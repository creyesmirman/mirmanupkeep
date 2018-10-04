# This is a collection of various functions used in the upkeep script. Not all may be implemented.

# Restart Option
restart_function() {
    while true; do
        read -p "Computer requires a restart. Do you want to restart now? (Y or N): " restartchoice
            case $restartchoice in
                [Yy] )
                    echo "Restarting"
                        sudo reboot
                        break;;
                [Nn] )
                    echo "Please restart using 'sudo reboot'"
                        break;;
                *)
                    echo "Please choose Y or N.";;
            esac
    done
}

# Dock Options
## Setting Dock for all users.
set_dock () {
    sudo dockutil --remove all --allhomes
    sudo dockutil --add '/Applications/Google Chrome.app' --allhomes
    sudo dockutil --add '/Applications/Managed Software Center.app' --allhomes
    sudo dockutil --add '/Applications/System Preferences.app' --allhomes
    sudo dockutil --add '~/Downloads' --allhomes
    sudo dockutil --add '/Applications' --allhomes
    sudo killall Dock 
}

## Setting Dock for specific user.
set_dock_user () {
    sudo dockutil --remove all /Users/$1
    sudo dockutil --add '/Applications/Google Chrome.app' /Users/$1
    sudo dockutil --add '/Applications/Managed Software Center.app' /Users/$1
    sudo dockutil --add '/Applications/System Preferences.app' /Users/$1
    sudo dockutil --add '~/Downloads' /Users/$1
    sudo dockutil --add '/Applications' /Users/$1
                
    if [ $(whoami) == $1 ]; then
        sudo killall Dock
    fi

}

# Rename machine
rename_machine () {
    echo "Renaming this machine. Please use approved naming convention."
    read -p "What is the username? : " rename
    
    sudo scutil --set HostName $rename
    sudo scutil --set LocalHostName $rename
    sudo scutil --set ComputerName $rename
    
    echo "Laptop successfully renamed to $rename! Please restart terminal to see changes."
    echo ""
    echo "Changes are listed below:"
    echo "HostName: $(sudo scutil --get HostName)"
    echo "LocalHostName: $(sudo scutil --get LocalHostName)"
    echo "ComputerName: $(sudo scutil --get ComputerName)"
    echo ""  
}

# Main Options
main_option () {
    PS3='Main Choices: 1:Printers 2:MSC Manifests 3:Rename Laptop 4:Add/Remove Users 5:Enable/Disable Securly 6:Update MSC 7:Set Dock 8:Edit User 9:Quit  '  
}

# Edit MSC Client Identifier
msc_identity () {
    sudo defaults write /Library/Preferences/ManagedInstalls.plist ClientIdentifier $1
}

# Adding a user
add_user () {
    read -p "What is the username of the user?: " ausername
    read -p "What is the real name of the user?: " arealname
    read -p "What is the password for this user?: " apassword

    usernum=$(dscl . -list /Users UniqueID | sort -nr -k 2 | head -1 | grep -oE '[0-9]+$')
    usernum=$((usernum+1))
        while true; do
            read -p "Is this user an Administrator for this laptop? [Y or N]: " adminchoice
            case $adminchoice in
                [Yy] ) echo "$ausername is set to Administrator."
                        aprimarygroupid=80
                break;;
                [Nn] ) echo "$ausername is set to Standard."
                        aprimarygroupid=20
                break;;
                * ) echo "Please select Y or N for Admin question."
            esac
        done

    sudo dscl . -create /Users/$ausername
    sudo dscl . -create /Users/$ausername UserShell /bin/bash
    sudo dscl . -create /Users/$ausername RealName "$arealname"
    sudo dscl . -create /Users/$ausername UniqueID $usernum
    sudo dscl . -create /Users/$ausername PrimaryGroupID $aprimarygroupid
    sudo dscl . -create /Users/$ausername NFSHomeDirectory /Users/$ausername
    sudo dscl . -passwd /Users/$ausername "$apassword"
    sudo dscl . -append /Groups/staff GroupMembership $ausername 
    sudo dscl . delete /Users/$ausername jpegphoto
    sudo dscl . create /Users/$ausername Picture /Library/User\ Pictures/Nature/Earth.png
    
    sudo createhomedir -c 2>&1 | grep -v "shell-init"
    sudo dseditgroup -o edit -a $ausername -t user _lpadmin

    echo "Creating user $ausername."
    echo "Creating real name $arealname."
    echo "Creating password of $apassword"
    echo "Creating Unique ID of $usernum."
    echo "$ausername can now add printers."
}

# List users allowed to be removed.
list_users () {
    echo "Users List:"
    echo "$(dscl . -list /Users | grep -v '_' | grep -v 'daemon' | grep -v 'root' | grep -v 'nobody' | grep -v '/' | grep -v 'remote')"
}

# Delete a user
delete_user () {
    read -p "What is the username to be removed?: " userdelete
    while true; do 
		read -p "You picked $userdelete. Is this right? [Y or N]" deletechoice
            case $deletechoice in 
                [Yy] )
                    echo "Checking if user exists..."
                    if [ -e /Users/$userdelete ]; then
                        echo "User $userdelete found! Removing..."
                        
                        sudo dseditgroup -o edit -d $userdelete -t user _lpadmin
                        sudo dscl . delete /Users/$userdelete
                        sudo rm -rf /Users/$userdelete
                    else
                        echo "User not found! Please try again."
                    fi
                break;;
                [Nn] ) 
                    echo "OK."
                break;;
                * ) echo "Please answer Y or N. ";;
            esac
    done
}

# Edit User function
edit_user () {
    read -p "What is the username to be edited?: " useredit
    stringcheck=$(dscl . -read /Groups/admin GroupMembership | awk -F ':' '{print $2}')
        if [[ $stringcheck = *"$useredit"* ]]; then
            while true; do
            read -p "$useredit is an Admin. Would you like to set $useredit as a Standard User? [Y or N]: " setuseraccount
                case $setuseraccount in
                    [Yy] )
                        echo "Setting $useredit to Standard..."
                        sudo dscl . -create /Users/$useredit PrimaryGroupID 20
                        sudo dseditgroup -o edit -d $useredit -t user admin
                        echo "$useredit is now a Standard account."
                        restart_function
                        break;;
                    [Nn] )
                        break;;
                    * )
                        echo "Please select Y or N." ;;
                esac
            done
        else
            while true; do
            read -p "$useredit is not an Admin. Would you like to set $useredit as an Administrator User? [Y or N]: " setadminaccount
                case $setadminaccount in
                    [Yy] )
                        echo "Setting $useredit to Administrator..."
                        sudo dscl . -create /Users/$useredit PrimaryGroupID 80
                        sudo dseditgroup -o edit -a $useredit -t user admin
                        echo "$useredit is now an Administrator account."
                        restart_function
                        break;;
                    [Nn] )
                        echo "OK."
                        break;;
                    * )
                        echo "Please select Y or N. " ;;
                esac
            done            
        fi
}

# DNS Status Checks on Wi-Fi interface.
dns_status () {
dns_check=$(networksetup -getdnsservers Wi-Fi)
if [[ $dns_check == *"There"* ]]; then
    echo "Securly is currently DISABLED."
elif [[ $dns_check == "50"* ]]; then 
    echo "Securly is currently ENABLED."
else
    echo "DHCP or Securly settings are not set! Please double check DNS settings."
fi 
}

dockpreqs () { 
    echo "Checking Pre-reqs"

    echo "Checking for Xcode command line tools.."
    if [ -e /usr/bin/xcode-select ]; then
    echo "Xcode command line tools already installed."
    else
    echo "No Xcode command line tools installed. Installing..."
    xcode-select --install
    wait
    echo "Xcode command line tools installed!"
    fi

    echo "Checking for Homebrew"
    if [ -e /usr/local/bin/brew ]; then
    echo "Homebrew already installed."
    else
    echo "Homebrew not found. Installing..."
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    wait
    echo "Homebrew installed!"
    fi

    echo "Checking for DockUtil"
    if [ -e /usr/local/bin/dockutil ]; then
    echo "DockUtil already installed."
    else
    echo "DockUtil not found. Installing..."
    brew install dockutil
    wait
    "DockUtil installed!"
    fi
}

dockarray () {
programsneeded=(brew dockutil xcode-select)
stuffitems=${programsneeded[*]}


for item in $stuffitems
  do
    if [ -e /usr/local/bin/$item ]; then
      echo "$item already installed."
    else
      case $item in
        homebrew)
            echo "Installing Homebrew..."
            /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
		    wait
            echo "Homebrew Installed!"
        ;;
		dockutil)
            echo "Installing DockUtil..."
	  		brew install dockutil
			wait
            echo "DockUtil Installed!"
		;;
        xcode-select)
            if [ -e /usr/bin/xcode-select ]; then
	            echo "xcode-select already installed."
            else
                echo "No xcode-select installed. Installing..."
                xcode-select --install
                wait
                echo "xcode-select installed!"
            fi	
        ;;
      esac
	fi
  done


}