# Autofauna

Track plant watering schedules, monitor sensors, and collaborate on plant care.

Autofauna is a plant care and environmental monitoring application that helps you stay on top of watering schedules, track environmental conditions, and manage plants across multiple projects.

**Smart Watering Schedules**
Log each watering with volume, units, and optional notes. Autofauna automatically calculates your watering frequency from historical data and shows you which plants need water now, which are due today, and which are coming up soon. A quick-water action lets you repeat your last watering with a single tap.

**Organize by Zones and Locations**
Group your plants into zones and locations that match your real-world setup — a living room shelf, a greenhouse bench, or an outdoor garden bed. Filter and sort plants by location, watering urgency, or name to find what you need fast.

**IoT Sensor Integration**
Connect temperature and humidity sensors to monitor your growing environment in real time. Autofauna provides a simple HTTP API that works with Arduino, ESP32, and other microcontrollers. View historical sensor readings to spot trends and protect sensitive plants.

**Water Quality Testing**
For aquatic and hydroponic systems, track water parameters including pH, TDS, temperature, nitrate, nitrite, ammonia, KH, and GH. Log tests over time to monitor the health of your water and catch problems early.

**Projects and Collaboration**
Create separate projects for different gardens, locations, or growing setups. Invite collaborators with viewer or editor roles so family members, roommates, or team members can help manage plant care. Each project has its own plants, sensors, zones, and API key.

**Sharing**
Generate a shareable link for any plant so friends, plant sitters, or anyone else can view its care history and log waterings without creating an account.

**Import and Export**
Bring your existing data with you. Import and export plants, watering history, and sensor readings as JSON for easy backup and migration.

**Activity Timeline**
View a combined timeline of waterings and log entries for each plant or tank. Keep notes on fertilizing, repotting, pest treatment, or any other event worth remembering.

**Available in English and Spanish**
Switch between English and Spanish at any time from the settings page.

Autofauna is built for anyone who cares for plants — whether you have a few houseplants on a windowsill or a full sensor-equipped greenhouse. It runs as a web application accessible from any device with a browser.

## IoT Sensor Integration
As project owner, enter API_KEY in Project Settings. Configure IoT device to transmit a GET request to `/sensors` with the following parameters:
* `temp`: latest temperature reading
* `humidity`: latest humidity reading
* `project_id`: found in Project Settings URL
* `API_KEY`: copy and past from Project Settings
* Example: `GET /sensors?temp=70&humidity=50&project_id=64&API_KEY=8d9ef5f1a2d50bc2a60f092268178f89a3fddf81ebfcdc635020f15eba8100a4ee21c461e429a042f`
 
## Environment
Deployed to https://plants.jefamirault.com with the following configuration:

* Ruby 3.2.2
* Rails 8.0.1
* OS: Ubuntu 22.04.4 LTS
* Database: Postgres 12.18
* Deployment: Capistrano 3.19.2
* Hosting: Basic Digital Ocean Droplet
  * 1 vCPU 
  * 2GB RAM
  * 50GB Disk
  * Intel CPU
