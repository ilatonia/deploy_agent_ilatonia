This project uses a Bash script (deploy_agent.sh) to automatically set up a Student Attendance Tracker workspace. The script creates the required folder structure, copies project files, allows users to update attendance thresholds, checks if Python 3 is installed, and verifies that all required files are present.

It also includes signal handling with trap, which allows the script to safely create an archive and clean up incomplete files if the user interrupts the process using Ctrl + C. The goal of this project is to demonstrate Bash scripting skills, automation, configuration management, environment validation, and basic process management.

Executing instructions
Clone my repository
git clone https://github.com/ilatonia/deploy_agent_ilatonia
cd /root/deploy_agent_ilatonia
Use CHMOD to add the execute permission
chmod u+x deploy_agent.sh
run the script
./deploy_agent.sh
Triggering the interupt signal
When the script is running, you can press ctrl + c or even send the kill signal, and the script will archive the current progress for you
