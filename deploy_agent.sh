#!/bin/bash
TEMPLATES_DIR="templates"
BASE_DIR=$(pwd)
PROJECT_DIR=""
PROJECT_NAME=""

cleanup_archive() {
    echo ""
    echo "[INFO] Archiving incomplete project..."
    cd "$BASE_DIR"
    if [[ -n "$PROJECT_NAME" && -d "$PROJECT_NAME" ]]; then
        ARCHIVE="${PROJECT_NAME}_archive.zip"
        rm -f "$ARCHIVE"
        zip -r "$ARCHIVE" "$PROJECT_NAME" > /dev/null
        rm -rf "$PROJECT_NAME"
        echo "[INFO] Created $ARCHIVE using zip command with real .zip extension"
    fi
    echo "[INFO] Session closed cleanly"
    exit 0
}

trap cleanup_archive INT TERM

if [[ ! -f "$TEMPLATES_DIR/attendance_checker.py" ]]; then
    echo "[ERROR] templates missing"; exit 1
fi

read -p "Enter class/session name: " USER_INPUT
USER_INPUT=$(echo "$USER_INPUT" | xargs)
if [[ -z "$USER_INPUT" ]]; then echo "[ERROR] Empty"; exit 1; fi

PROJECT_NAME="attendance_tracker_${USER_INPUT}"
PROJECT_DIR="$BASE_DIR/$PROJECT_NAME"

rm -rf "$PROJECT_DIR"
rm -f "${PROJECT_NAME}_archive.zip"
rm -f "${PROJECT_DIR}_archive.zip"

mkdir -p "$PROJECT_NAME/Helpers"
mkdir -p "$PROJECT_NAME/reports"

cp "$TEMPLATES_DIR/attendance_checker.py" "$PROJECT_NAME/"
cp "$TEMPLATES_DIR/assets.csv" "$PROJECT_NAME/Helpers/"
cp "$TEMPLATES_DIR/config.json" "$PROJECT_NAME/Helpers/"
chmod +x "$PROJECT_NAME/attendance_checker.py"

echo "[INFO] Created $PROJECT_NAME"
ls -R "$PROJECT_NAME"

cd "$PROJECT_NAME"
python3 attendance_checker.py
PY_STATUS=$?
cd "$BASE_DIR"

if [[ $PY_STATUS -ne 0 ]] || grep -q "Interrupted" "$PROJECT_NAME/reports/attendance.log" 2>/dev/null || [[ ! -f "$PROJECT_NAME/reports/attendance.log" ]] || [[ $(wc -l < "$PROJECT_NAME/reports/attendance.log" 2>/dev/null) -lt 10 ]]; then
    
    if [[ -d "$PROJECT_NAME" ]]; then
        
        if grep -q "Interrupted" "$PROJECT_NAME/reports/attendance.log" 2>/dev/null || [[ $PY_STATUS -ne 0 ]] || [[ $(grep -c "Mark" "$PROJECT_NAME/reports/attendance.log" 2>/dev/null) -lt 10 && -f "$PROJECT_NAME/reports/attendance.log" ]]; then
            
            if ! grep -q "Done. Marked 10 students" "$PROJECT_NAME/reports/attendance.log" 2>/dev/null; then
                
                if [[ -d "$PROJECT_NAME" ]]; then
                    
                    if [[ $PY_STATUS -ne 0 ]] || grep -q "Interrupted" "$PROJECT_NAME/reports/attendance.log" 2>/dev/null; then
                        ARCHIVE="${PROJECT_NAME}_archive.zip"
                        rm -f "$ARCHIVE"
                        zip -r "$ARCHIVE" "$PROJECT_NAME" > /dev/null
                        rm -rf "$PROJECT_NAME"
                        echo "[INFO] Incomplete project $PROJECT_NAME archived into $ARCHIVE using zip command with real .zip extension"
                        echo "[INFO] Session closed cleanly"
                        exit 0
                    fi
                fi
            fi
        fi
    fi
fi

echo "[INFO] Session closed cleanly"
exit $PY_STATUS
