package commands

import (
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"

	xpath "github.com/uhppoted/uhppoted-lib/encoding/plist"
)

var UNDAEMONIZE = Undaemonize{
	plist:   fmt.Sprintf("com.github.uhppoted.%s.plist", SERVICE),
	workdir: "/usr/local/var/com.github.uhppoted",
	logdir:  "/usr/local/var/com.github.uhppoted/logs",
	config:  "/usr/local/etc/com.github.uhppoted/uhppoted.conf",
}

type Undaemonize struct {
	plist   string
	workdir string
	logdir  string
	config  string
}

func (cmd *Undaemonize) Name() string {
	return "undaemonize"
}

func (cmd *Undaemonize) FlagSet() *flag.FlagSet {
	return flag.NewFlagSet("undaemonize", flag.ExitOnError)
}

func (cmd *Undaemonize) Description() string {
	return fmt.Sprintf("Deregisters %s as a service/daemon", SERVICE)
}

func (cmd *Undaemonize) Usage() string {
	return ""
}

func (cmd *Undaemonize) Help() {
	fmt.Println()
	fmt.Printf("  Usage: %s undaemonize\n", SERVICE)
	fmt.Println()
	fmt.Printf("    Deregisters %s from launchd as a service/daemon", SERVICE)
	fmt.Println()

	helpOptions(cmd.FlagSet())
}

func (cmd *Undaemonize) Execute(args ...interface{}) error {
	fmt.Println("   ... undaemonizing")

	executable, err := cmd.launchd()
	if err != nil {
		return err
	}

	if err := cmd.logrotate(); err != nil {
		return err
	}

	if err := cmd.clean(); err != nil {
		return err
	}

	if err := cmd.firewall(executable); err != nil {
		return err
	}

	fmt.Printf("   ... com.github.uhppoted.%s unregistered as a LaunchDaemon\n", SERVICE)
	fmt.Printf(`
   NOTE: Configuration files in %s,
               working files in %s,
               and log files in %s
               were not removed and should be deleted manually
`, filepath.Dir(cmd.config), cmd.workdir, cmd.logdir)
	fmt.Println()

	return nil
}

func (cmd *Undaemonize) parse(path string) (*info, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}

	defer f.Close()

	i := info{}
	decoder := xpath.NewDecoder(f)
	err = decoder.Decode(&i)
	if err != nil {
		return nil, err
	}

	return &i, nil
}

func (cmd *Undaemonize) launchd() (string, error) {
	label := fmt.Sprintf("com.github.uhppoted.%s", SERVICE)

	path := filepath.Join("/Library/LaunchDaemons", cmd.plist)
	_, err := os.Stat(path)
	if err != nil && !os.IsNotExist(err) {
		return "", err
	}

	if os.IsNotExist(err) {
		fmt.Printf("   ... nothing to do for 'launchd'   (%s does not exist)\n", path)
		return "", nil
	}

	// stop daemon
	fmt.Println("   ... unloading LaunchDaemon")
	command := exec.Command("launchctl", "unload", path)
	out, err := command.CombinedOutput()
	fmt.Println()
	fmt.Printf("   > %s", out)
	fmt.Println()
	if err != nil {
		return "", fmt.Errorf("Failed to unload '%s' (%v)\n", label, err)
	}

	// get launchd executable from plist

	f, err := os.Open(path)
	if err != nil {
		return "", err
	}

	pl := plist{}
	decoder := xpath.NewDecoder(f)
	if err = decoder.Decode(&pl); err != nil {
		f.Close()
		return "", err
	}

	f.Close()

	// remove plist file
	fmt.Printf("   ... removing '%s'\n", path)
	err = os.Remove(path)
	if err != nil {
		return pl.Program, err
	}

	return pl.Program, nil
}

func (cmd *Undaemonize) logrotate() error {
	path := filepath.Join("/etc/newsyslog.d", fmt.Sprintf("%s.conf", SERVICE))

	_, err := os.Stat(path)
	if err != nil && !os.IsNotExist(err) {
		return err
	}

	if os.IsNotExist(err) {
		fmt.Printf("   ... nothing to do for 'newsyslog' (%s does not exist)\n", path)
		return nil
	}

	fmt.Printf("   ... removing '%s'\n", path)

	return os.Remove(path)
}

func (cmd *Undaemonize) clean() error {
	files := []string{
		filepath.Join(cmd.workdir, fmt.Sprintf("%s.pid", SERVICE)),
	}

	directories := []string{
		cmd.logdir,
		cmd.workdir,
	}

	for _, f := range files {
		fmt.Printf("   ... removing '%s'\n", f)
		if err := os.Remove(f); err != nil && !os.IsNotExist(err) {
			return err
		}
	}

	for _, dir := range directories {
		fmt.Printf("   ... removing '%s'\n", dir)
		if err := os.Remove(dir); err != nil && !os.IsNotExist(err) {
			patherr, ok := err.(*os.PathError)
			if !ok {
				return err
			}

			syserr, ok := patherr.Err.(syscall.Errno)
			if !ok {
				return err
			}

			if syserr != syscall.ENOTEMPTY {
				return err
			}

			fmt.Printf("   ... WARNING: could not remove directory '%s' (%v)\n", dir, syserr)
		}
	}

	return nil
}

func (cmd *Undaemonize) firewall(executable string) error {
	if executable == "" {
		return nil
	}

	fmt.Println()
	fmt.Println("   ***")
	fmt.Printf("   *** WARNING: removing '%s' from the application firewall\n", SERVICE)
	fmt.Println("   ***")
	fmt.Println()

	path := executable
	command := exec.Command("/usr/libexec/ApplicationFirewall/socketfilterfw", "--getglobalstate")
	out, err := command.CombinedOutput()
	fmt.Printf("   > %s", out)
	if err != nil {
		return fmt.Errorf("Failed to retrieve application firewall global state (%v)\n", err)
	}

	if strings.Contains(string(out), "State = 1") {
		command = exec.Command("/usr/libexec/ApplicationFirewall/socketfilterfw", "--setglobalstate", "off")
		out, err = command.CombinedOutput()
		fmt.Printf("   > %s", out)
		if err != nil {
			return fmt.Errorf("Failed to disable the application firewall (%v)\n", err)
		}

		command = exec.Command("/usr/libexec/ApplicationFirewall/socketfilterfw", "--remove", path)
		out, err = command.CombinedOutput()
		fmt.Printf("   > %s", out)
		if err != nil {
			return fmt.Errorf("Failed to remove 'uhppoted-rest' from the application firewall (%v)\n", err)
		}

		command = exec.Command("/usr/libexec/ApplicationFirewall/socketfilterfw", "--setglobalstate", "on")
		out, err = command.CombinedOutput()
		fmt.Printf("   > %s", out)
		if err != nil {
			return fmt.Errorf("Failed to re-enable the application firewall (%v)\n", err)
		}

		fmt.Println()
	}

	return nil
}
