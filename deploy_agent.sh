#!/bin/bash
PROJECT_NAME=""
cleanup() {
    echo ""
    echo "[INFO] Interrupted! Archiving..."
    if [ -d "$PROJECT_NAME" ]; then
        zip -r ${PROJECT_NAME}_archive.zip $PROJECT_NAME > /dev/null 2>&1
        rm -rf $PROJECT_NAME
        echo "[INFO] Archived to ${PROJECT_NAME}_archive.zip"
    fi
    exit 0
}
trap cleanup SIGINT SIGTSTP

echo "1) Deploy"
echo "2) Run"
echo "3) Archive"
read -p "Choice: " choice

if [ "$choice" == "1" ]; then
    command -v python3 >/dev/null || { echo "python3 missing"; exit 1; }
    command -v zip >/dev/null || { echo "zip missing"; exit 1; }
    echo "[OK] preflight ok"

    read -p "Project name: " name
    PROJECT_NAME="attendance_tracker_$name"
    if [ -d "$PROJECT_NAME" ]; then
        read -p "Overwrite? y/n: " o
        [ "$o" != "y" ] && exit 0
        rm -rf $PROJECT_NAME
    fi

    mkdir -p $PROJECT_NAME/Helpers $PROJECT_NAME/reports
    [ -f templates/attendance_checker.py ] && cp templates/attendance_checker.py $PROJECT_NAME/ || echo "print('ok')" > $PROJECT_NAME/attendance_checker.py
    [ -f templates/config.json ] && cp templates/config.json $PROJECT_NAME/Helpers/ || echo '{"total_sessions":1,"thresholds":{"warning":75,"failure":50}}' > $PROJECT_NAME/Helpers/config.json

    echo "A) Copy template"
    echo "B) Generate"
    read -p "A/B: " r
    if [ "$r" == "A" ] || [ "$r" == "a" ]; then
        [ -f templates/assets.csv ] && { head -1 templates/assets.csv > $PROJECT_NAME/Helpers/assets.csv; tail -n +2 templates/assets.csv | head -5 >> $PROJECT_NAME/Helpers/assets.csv; } || echo "Email,Name" > $PROJECT_NAME/Helpers/assets.csv
        sed -i 's/"total_sessions": .*/"total_sessions": 5,/' $PROJECT_NAME/Helpers/config.json
    else
        echo "Email,Name,Attendance,Absence" > $PROJECT_NAME/Helpers/assets.csv
        echo "a@a.com,A,0,0" >> $PROJECT_NAME/Helpers/assets.csv
        echo "b@b.com,B,0,0" >> $PROJECT_NAME/Helpers/assets.csv
        echo "c@c.com,C,0,0" >> $PROJECT_NAME/Helpers/assets.csv
        echo "d@d.com,D,0,0" >> $PROJECT_NAME/Helpers/assets.csv
        echo "e@e.com,E,0,0" >> $PROJECT_NAME/Helpers/assets.csv
        sed -i 's/"total_sessions": .*/"total_sessions": 1,/' $PROJECT_NAME/Helpers/config.json
    fi

    chmod +x $PROJECT_NAME/attendance_checker.py
    chmod 600 $PROJECT_NAME/Helpers/config.json
    ls -l $PROJECT_NAME/attendance_checker.py $PROJECT_NAME/Helpers/config.json

    read -p "Update thresholds y/n: " u
    if [ "$u" == "y" ]; then
        read -p "warning: " w
        read -p "failure: " f
        [[ $w =~ ^[0-9]+$ ]] && sed -i "s/\"warning\": [0-9]*/\"warning\": $w/" $PROJECT_NAME/Helpers/config.json
        [[ $f =~ ^[0-9]+$ ]] && sed -i "s/\"failure\": [0-9]*/\"failure\": $f/" $PROJECT_NAME/Helpers/config.json
    fi
    echo "Deploy done"

elif [ "$choice" == "2" ]; then
    read -p "Project name: " name
    PROJECT_NAME="attendance_tracker_$name"
    cd $PROJECT_NAME && python3 attendance_checker.py; cd ..

elif [ "$choice" == "3" ]; then
    read -p "Project name: " name
    PROJECT_NAME="attendance_tracker_$name"
    T=$(date +"%Y%m%d_%H%M%S")
    mkdir -p $PROJECT_NAME/archives/attendance $PROJECT_NAME/archives/absent
    [ -f $PROJECT_NAME/reports/attendance.log ] && cp $PROJECT_NAME/reports/attendance.log $PROJECT_NAME/archives/attendance/attendance_$T.log && echo "archived attendance" || echo "attendance.log not found"
    [ -f $PROJECT_NAME/reports/absent.log ] && cp $PROJECT_NAME/reports/absent.log $PROJECT_NAME/archives/absent/absent_$T.log && echo "archived absent" || echo "absent.log not found"
fi
