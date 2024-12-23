# README

Dynamically manage maintenance and care for your plants.

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
