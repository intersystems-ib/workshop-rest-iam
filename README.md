# Workshop: REST and InterSystems API Manager
This repository contains the materials and some examples you can use to learn the basic concepts of REST and IAM. 

You can find more in-depth information in https://learning.intersystems.com.

# What do you need to install? 
* [Git](https://git-scm.com/downloads) 
* [Docker](https://www.docker.com/products/docker-desktop) (if you are using Windows, make sure you set your Docker installation to use "Linux containers").
* [Docker Compose](https://docs.docker.com/compose/install/)
* [Visual Studio Code](https://code.visualstudio.com/download) + [InterSystems ObjectScript VSCode Extension](https://marketplace.visualstudio.com/items?itemName=daimor.vscode-objectscript)
* [Postman](https://www.getpostman.com/downloads/)

# Setup

## IRIS image
You need to setup your access to InterSystems Container Registry to download IRIS limited access images.

Have a look at this [Introducing InterSystems Container Registry](https://community.intersystems.com/post/introducing-intersystems-container-registry) on [Developer Community](https://community.intersystems.com).

* Log-in into https://containers.intersystems.com/ using your WRC credentials and get a *token*.
* Set up docker login in your computer:
```
docker login -u="user" -p="token" containers.intersystems.com
```
* Get InterSystems IRIS image:
```
docker pull containers.intersystems.com/intersystems/iris:2020.2.0.211.0
```

## IAM Image & License
In [WRC Software Distribution](https://wrc.intersystems.com/wrc/coDistribution.csp):
* Components > Download *IAM 0.34* image and then load it:
```
docker load -i iam_image.tar
```
* Get your evaluation license with IAM enabled in *Evaluations*.

## Build the image
Build the image we will use during the workshop:

```console
$ git clone https://github.com/intersystems-ib/workshop-rest-iam
$ cd workshop-rest-iam
$ docker-compose build
```

# Examples

## (a). Run containers and access IAM
* Run the containers we will use in the workshop and check you access them:
```
docker-compose up -d
```
* Access [IRIS Management Portal](http://localhost:52773/csp/sys/UtilHome.csp) using `superuser`/`SYS`.
* Access [IAM Management Portal](http://localhost:8002/overview).

## (b). OpenAPI specification
* We will use an OpenAPI specification as a starting point to build a REST API in IRIS.
* Check the YAML version in [shared/leaderboard-api-v1.yaml](shared/leaderboard-api-v1.yaml) and the JSON version in [shared/leaderboard-api-v1.json](shared/leaderboard-api-v1.json)
* Have a look at it using https://editor.swagger.io or https://app.swaggerhub.com/login.

## (c). Data classes and %JSON.Adaptor
* The sample API we are developing will use two main persistent (table) classes that will hold data for us. 
* Have a look at [Webinar.Data.Player](src/Webinar/Data/Player.cls) and [Webinar.Data.Team](src/Webinar/Data/Team.cls).
* Notice that both classes inherit from `%Persistent` and `%JSON.Adaptor`.
* If you are not familiar with `%JSON.Adaptor` and transforming objects to and from JSON, check this great article [JSON Enhancements](https://community.intersystems.com/post/json-enhancements) on Developer Community.
* Check also the generated data through *System Explorer > SQL*.


## (d). Generate API from OpenAPI specifications
* Let's build the API implementation skeleton from the OpenAPI specification using `^%REST` wizard.
* Open a WebTerminal session using http://localhost:52773/terminal/ and type: 
```
WEBINAR > do ^%REST 
REST Command Line Interface (CLI) helps you CREATE or DELETE a REST application.Enter an application name or (L)ist all REST applications (L): L 
Applications        Web Applications
------------        ----------------
Enter an application name or (L)ist all REST applications (L): Webinar.API.Leaderboard.v1
REST application not found: Webinar.API.Leaderboard.v1
Do you want to create a new REST application? Y or N (Y): Y
File path or absolute URL of a swagger document.
If no document specified, then create an empty application.
OpenAPI 2.0 swagger: /shared/leaderboard-api-v1.json

OpenAPI 2.0 swagger document: /shared/leaderboard-api-v1.json
Confirm operation, Y or N (Y): Y
-----Creating REST application: Webinar.API.Leaderboard.v1-----
CREATE Webinar.API.Leaderboard.v1.spec
GENERATE Webinar.API.Leaderboard.v1.disp
CREATE Webinar.API.Leaderboard.v1.impl
REST application successfully created.

Create a web application for the REST application? Y or N (Y): Y
Specify web application name. Default is /csp/Webinar/API/Leaderboard/v1
Web application name: /leaderboard/api/v1

-----Deploying REST application: Webinar.API.Leaderboard.v1-----
Application Webinar.API.Leaderboard.v1 deployed to /leaderboard/api/v1
```

## (e) Implement REST API methods
* Using VS Code, complete the code of the following methods in `Webinar.API.Leaderboard.v1.impl`.

### addPlayer
```
ClassMethod addPlayer(body As %DynamicObject) As %DynamicObject
{
    set player = ##class(Webinar.Data.Player).%New()
    do player.%JSONImport(body)
    set sc = player.%Save()
    if $$$ISERR(sc) {
    	do ..%SetStatusCode(405)
    	quit ""
    }
    do player.%JSONExportToStream(.stream)
    quit stream
}
```

### getPlayers
```
ClassMethod getPlayers() As %DynamicObject
{
    set sql = "SELECT Id, Name, Alias FROM Webinar_Data.Player order by Score"
    set statement = ##class(%SQL.Statement).%New()
    set sc = statement.%Prepare(sql)
    set rs = statement.%Execute()
    
    set array = []
    while rs.%Next() {
    	do array.%Push( 
    		{
    			"Id": (rs.%Get("Id")),
    			"Name": (rs.%Get("Name")),
    			"Alias": (rs.%Get("Alias"))
    		})
    }
    
    quit array
}
```

### getPlayerById
```
ClassMethod getPlayerById(playerId As %Integer) As %DynamicObject
{
    set player = ##class(Webinar.Data.Player).%OpenId(playerId)
    if '$isobject(player) {
    	do ..%SetStatusCode(404)
    	quit ""
    }
    do player.%JSONExportToStream(.stream)
    quit stream
}
```

### updatePlayer
```
ClassMethod updatePlayer(playerId As %Integer, body As %DynamicObject) As %DynamicObject
{
    set player = ##class(Webinar.Data.Player).%OpenId(playerId)
    if '$isobject(player) {
    	do ..%SetStatusCode(404)
    	quit ""
    }
    do player.%JSONImport(body)
    do player.%Save()
    do player.%JSONExportToStream(.stream)
    quit stream
}
```

### deletePlayer
```
ClassMethod deletePlayer(playerId As %Integer) As %DynamicObject
{
    set sc = ##class(Webinar.Data.Player).%DeleteId(playerId)
    if $$$ISERR(sc) {
    	do ..%SetStatusCode(404)
    }
    quit ""
}
```

## (f) Test the REST API in IRIS
* Load in Postman the collection in [postman/leaderboard-api.postman_collection.json](postman/leaderboard-api.postman_collection.json).
* Try these requests: `GET Player`, `GET Players`, `POST Player` y `PUT Player`

