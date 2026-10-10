#!/bin/bash

PROJECT_NAME=""


cleanup() {
    echo ""
    echo "[INFO] Interrupted! Cleaning up..."
    if [ -d "$PROJECT_NAME" ]; then
        zip -r ${PROJECT_NAME}_archive.zip $PROJECT_NAME > /dev/null
        rm -rf $PROJECT_NAME
        echo "[INFO] Archived to ${PROJECT_NAME}_archive.zip"
    fi
    exit 1
}

trap cleanup SIGINT SIGTSTP

echo "Attendance Tracker Deploy Agent"
echo "1) Deploy application"
echo "2) Run application"
echo "3) Archive logs"
echo "4) Exit"

read -p "Choose option: " choice

if [ "$choice" == "1" ]; then
    
    if ! command -v python3 > /dev/null; then
        echo "[ERROR] python3 not found"
        exit 1
    fi
    if ! command -v zip > /dev/null; then
        echo "[ERROR] zip not found"
        exit 1
    fi
    echo "[OK] python3 found"
    echo "[OK] zip found"

    read -p "Enter project name: " name
    PROJECT_NAME="attendance_tracker_$name"


    if [ -d "$PROJECT_NAME" ]; then
        read -p "Folder exists, overwrite? y/n: " over
        if [ "$over" != "y" ]; then
            echo "Cancelled"
            exit 0
        fi
        rm -rf $PROJECT_NAME
    fi

    mkdir -p $PROJECT_NAME/Helpers
    mkdir -p $PROJECT_NAME/reports

    cp templates/attendance_checker.py $PROJECT_NAME/
    cp templates/config.json $PROJECT_NAME/Helpers/

    echo "How would you like to build roster?"
    echo "A) Copy from template"
    echo "B) Generate new"
    read -p "Enter A or B: " roster

    if [ "$roster" == "A" ] || [ "$roster" == "a" ]; then
        echo "Email,Name,Attendance,Absence" > $PROJECT_NAME/Helpers/assets.csv
        cat templates/assets.csv | tail -n +2 | head -n 5 >> $PROJECT_NAME/Helpers/assets.csv
        # copy = 4 old sessions, now total 5
        sed -i 's/"total_sessions": .*/"total_sessions": 5,/' $PROJECT_NAME/Helpers/config.json
        echo "[INFO] Copied 5 students"
    else
        echo "Email,Name,Attendance,Absence" > $PROJECT_NAME/Helpers/assets.csv
        echo "james@test.com,James,0,0" >> $PROJECT_NAME/Helpers/assets.csv
        echo "aline@test.com,Aline,0,0" >> $PROJECT_NAME/Helpers/assets.csv
        echo "kevin@test.com,Kevin,0,0" >> $PROJECT_NAME/Helpers/assets.csv
        echo "divine@test.com,Divine,0,0" >> $PROJECT_NAME/Helpers/assets.csv
        echo "bruno@test.com,Bruno,0,0" >> $PROJECT_NAME/Helpers/assets.csv
        sed -i 's/"total_sessions": .*/"total_sessions": 1,/' $PROJECT_NAME/Helpers/config.json
        echo "[INFO] Generated 5 students"
    fi

    chmod +x $PROJECT_NAME/attendance_checker.py
    chmod 600 $PROJECT_NAME/Helpers/config.json

    echo "[INFO] Created $PROJECT_NAME"
    ls -R $PROJECT_NAME

    read -p "Do you want to update thresholds? y/n: " up
    if [ "$up" == "y" ]; then
        read -p "Enter warning: " w
        read -p "Enter failure: " f
        # check if number
        if [[ "$w" =~ ^[0-9]+$ ]]; then
            sed -i "s/\"warning\": [0-9]*/\"warning\": $w/" $PROJECT_NAME/Helpers/config.json
        fi
        if [[ "$f" =~ ^[0-9]+$ ]]; then
            sed -i "s/\"failure\": [0-9]*/\"failure\": $f/" $PROJECT_NAME/Helpers/config.json
        fi
    fi

    echo "[INFO] Deploy done"

elif [ "$choice" == "2" ]; then
    read -p "Enter project name: " name
    PROJECT_NAME="attendance_tracker_$name"
    cd $PROJECT_NAME
    python3 attendance_checker.py
    cd ..

elif [ "$choice" == "3" ]; then
    read -p "Enter project name: " name
    PROJECT_NAME="attendance_tracker_$name"
    time=$(date +"%Y%m%d_%H%M%S")
    mkdir -p $PROJECT_NAME/archives/attendance
    mkdir -p $PROJECT_NAME/archives/absent
    
    if [ -f "$PROJECT_NAME/reports/attendance.log" ]; then
        cp $PROJECT_NAME/reports/attendance.log $PROJECT_NAME/archives/attendance/attendance_$time.log
        echo "Archived attendance"
    else
        echo "[INFO] attendance.log not found"
    fi

    if [ -f "$PROJECT_NAME/reports/absent.log" ]; then
        cp $PROJECT_NAME/reports/absent.log $PROJECT_NAME/archives/absent/absent_$time.log
        echo "Archived absent"
    else
        echo "[INFO] absent.log not found"
    fi
else
    echo "Exit"
    exit 0
fi
