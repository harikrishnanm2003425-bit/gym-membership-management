# Fitness Center & Gym Membership Management

A MySQL project for managing gym members, trainers, subscriptions and entry logs.
It works as a **CRM / TPS** system and gives **DSS** reports for the manager.

## Features
- **Tables:** `Gym_Members`, `Trainers`, `Subscriptions`, `Access_Logs`
- **TPS (transactions):** register member, take payment and activate, check-in, check-out. Every transaction uses commit / rollback.
- **DSS output:**
  - Active vs Inactive member ratio (`vw_active_inactive_ratio`)
  - Trainer utilization (`vw_trainer_utilization`)
- **CRM views:** plans expiring soon, renewal leads

## Files
| File | Description |
|---|---|
| `gym_management_mysql57.sql` | Creates the database, tables, sample data, procedures and views |
| `gym_tps_demo.sql` | Extra TPS transactions and demo commands |
| `Gym_Management_Project_Report.docx` | Full project report |
| `diagrams/gym_dfd_level1.drawio` | DFD Level 1 (open in diagrams.net) |
| `diagrams/gym_er_diagram.drawio` | ER diagram (open in diagrams.net) |
| `diagrams/gym_model.mwb` | ER model (open in MySQL Workbench) |
| `diagrams/DFD_Level1.png`, `diagrams/ER_Diagram.png` | Diagram pictures |
| `screenshots/` | Output screenshots |

## How to run
1. Install MySQL Server and MySQL Workbench.
2. Open Workbench and connect to your local server.
3. Open `gym_management_mysql57.sql` and click the lightning bolt to run it.
4. Run the DSS reports:
   ```sql
   USE gym_db;
   SELECT * FROM vw_active_inactive_ratio;
   SELECT * FROM vw_trainer_utilization;
   ```
5. Optional: run `gym_tps_demo.sql`, then follow the demo lines at the bottom of that file.

## Sample results
- Active members: 5 (62.5%), Inactive members: 3 (37.5%)
- Trainer utilization: Arjun Rao 75% (Optimal), Meera Nair 37.5% and Kiran Shetty 0% (Under-utilised)

## Tools
MySQL, MySQL Workbench, Draw.io (diagrams.net), Microsoft Word

## Author
Your Name Here
