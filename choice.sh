#!/bin/bash

PS3='Main Choices: 1:Printers 2:MSC Manifests 3:Rename Laptop 4:Add/Remove Users 5:Enable/Disable Securly 6:Update MSC 7:Quit '
options=("Printers" "MSC Manifest" "Rename Laptop" "Add/Remove Users" "Enable/Disable Securly" "Update MSC" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Printers")
            isadmin=$(dscl . -read /Groups/admin GroupMembership | grep $(whoami))
            if [ "$isadmin" == "" ]; then
                echo "Please change to an admin account and run me again."; exit 0
            else
                echo -n "What is the username of the user?(ex.josmith2099): "
		        read student
                    while true; do 
		                read -p "You picked $student. Is this right? [Y or N]" choice
                        case $choice in 
                            [Yy] )
                            echo "Checking if user exists..."
                            if [ -e /Users/$student ]; then
                                echo "User $student found! Appending to lpadmin group..."
                                # Just for future reference, to delete user from lpadmin:
                                # sudo dseditgroup -o edit -d $student -t user _lpadmin
                                sudo dseditgroup -o edit -a $student -t user _lpadmin
                                echo "$student added! These are the current users in _lpadmin(users that can add printers): "
                                echo "$(dscl . -read /Groups/_lpadmin | grep 'GroupMembership')"
                                echo " "
                            else
                                echo "User not found! Please try again."
                            break
                            fi
                            break;;
                            [Nn] ) echo "OK."; break;;
                            * ) echo "Please answer Y or N. ";;
                        esac
                    done
            fi
            ;;
        "MSC Manifest")
            echo "Changing MSC Manifest"
            echo "Manifest (Client Identifier) of this pc: $(defaults read /Library/Preferences/ManagedInstalls.plist ClientIdentifier)"           
                while true; do
                    read -p "Would you like to change it? [Y or N] " manifestchoice
                    case $manifestchoice in
                        [Yy] ) PS3='Please choose from the following manifests: '
                        options=('student_us' 'student_ls' 'faculty')
                        select manifestopt in "${options[@]}"
                        do 
                            case $manifestopt in
                                "student_us")
                                    echo "Changing manifest to $manifestopt"
                                    sudo defaults write /Library/Preferences/ManagedInstalls.plist ClientIdentifier $manifestopt
                                    PS3='Main Choices: 1:Printers 2:MSC Manifests 3:Rename Laptop 4:Add/Remove Users 5:Enable/Disable Securly 6:Update MSC 7:Quit '
                                    break;;
                                "student_ls")
                                    echo "Changing manifest to $manifestopt"
                                    sudo defaults write /Library/Preferences/ManagedInstalls.plist ClientIdentifier $manifestopt
                                    PS3='Main Choices: 1:Printers 2:MSC Manifests 3:Rename Laptop 4:Add/Remove Users 5:Enable/Disable Securly 6:Update MSC 7:Quit '
                                    break;;
                                "faculty")
                                    echo "Changing manifest to $manifestopt"
                                    sudo defaults write /Library/Preferences/ManagedInstalls.plist ClientIdentifier $manifestopt
                                    PS3='Main Choices: 1:Printers 2:MSC Manifests 3:Rename Laptop 4:Add/Remove Users 5:Enable/Disable Securly 6:Update MSC 7:Quit '
                                    break;;
                                *) echo "Choose a valid manifest number."
                            esac
                        done
                        break;;
                        [Nn] ) echo "OK."
                        break;;
                        * ) echo "Please answer Y or N. ";;
                    esac
                done
            ;;
        "Rename Laptop")
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
            ;;
        "Add/Remove Users")
            echo "Adding / Removing Users"
                while true; do
                read -p "Are you trying to (A)dd or (R)emove a user?: " addremovechoice
                    case $addremovechoice in
                    [Aa] )
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
                        sudo createhomedir -c -u $ausername

                        echo "Creating user $ausername."
                        echo "Creating real name $arealname."
                        echo "Creating password of $apassword"
                        echo "Creating Unique ID of $usernum."
                        echo "Please log in as the new user to enable other upkeep options."
                        break;;
                    [Rr] ) 
                        read -p "What is the username to be removed?: " userdelete
                                while true; do 
		                            read -p "You picked $userdelete. Is this right? [Y or N]" deletechoice
                                    case $deletechoice in 
                                        [Yy] )
                                            echo "Checking if user exists..."
                                            if [ -e /Users/$userdelete ]; then
                                            echo "User $userdelete found! Removing..."
                                            sudo dscl . delete /Users/$userdelete
                                            sudo rm -rf /Users/$userdelete
                                            else
                                            echo "User not found! Please try again."
                                            fi
                                            break;;
                                        [Nn] ) echo "OK.";break;;
                                        * ) echo "Please answer Y or N. ";;
                                    esac
                                done
                                break;;
                    * )
                        echo "Please use A or R."
                    esac
                done
            ;;
        "Enable/Disable Securly")
            echo "Securly Settings"
                while true; do
                read -p "Do you want to (E)nable or (D)isable Securly?: " securlychoice
                    case $securlychoice in
                    [Ee] )
                        networksetup -setdnsservers Wi-Fi 50.18.216.174 50.18.216.175
                        sudo killall -HUP mDNSResponder
                        echo "Securly Enabled."
                        break;;
                    [Dd] )
                        networksetup -setdnsservers Wi-Fi Empty
                        sudo killall -HUP mDNSResponder
                        echo "Securly Disabled."
                        break;;
                    * )
                        echo "Please select 'E' or 'D'."
                    esac
                done
            ;;
        "Update MSC")
            echo "Updating MSC using the $(defaults read /Library/Preferences/ManagedInstalls.plist ClientIdentifier) Manifest."
            echo "If there are system updates, you may need to reboot. Use the 'sudo reboot' command."
            sudo managedsoftwareupdate && sudo managedsoftwareupdate --installonly
            ;;

        "Quit")
            echo "Thank you."
            break;;
        *) echo "Invalid option";;
    esac
done
