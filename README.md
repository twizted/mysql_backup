MySQL backup script
===================

# Description
This script creates compressed backups of the preset database to a preset
destination (like a mounted share), and it handles auto-removal of backup files
older than 30 days. Once the variables are set it can simply be called from
cron-ish systems.

# Requirements
No additional requirements.
