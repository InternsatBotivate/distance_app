# vendor_distance_app

A new Flutter project.


Ohk I'm very impressed with what I have done, but before we proceed, let me explain to you what I want to build.


first lets start with some terminologies,


user marker: the marker that can be adjusted by user. Initially set to user's current location.


vendor marker: the marker showing the location of a vendor.


Now I basically want a app, which tells user there nearby vendors, with distance and duration.


So when the user chooses a location, only vendors close by popup, initial all vendors are visible but small, and the vendor marker shows the name, and a line is drawn from initial position to the vendor marker. Only vendor in a certain radius have the line drawn, and there icon size is increased. The line connecting vendor and user marker, show duration and distance, for which I have an api. 


To start this process, the user clicks a find button, which basically hits request to my api, with the initial points set at user location, and final points as vendors that are close by. to find the close by vendors we use a normal mathematical function that finds the distances based on latitude and longitude, but this distance just to show that the location is in radius, to get the real distance we use the api. The use can change the radius. In a modal, but that is optional. 


When the user clicks on a vendor, it show the following details in a bottom sheet,


Name:

Address:

Distance: (fetched from api)

Duration: (fetched from api)



If the user click on a non highlighted vendor, the the duration and distance data is fetched from the api on click. 

this sheet also has a button that redirects to google maps with directions.


The user can also input the location in a text box, which sends a request to an geocoding api I have, which basically if successful returns lat and lon of the location, so we can set the user marker there, if unsuccesfull we can show user a friendly error message saying invalid location or something. Also this app should have good loading screens and stuff, but thats all for a later point.


Is it doable?