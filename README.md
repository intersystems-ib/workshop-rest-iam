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

## IAM Image
In [WRC Software Distribution](https://wrc.intersystems.com/wrc/coDistribution.csp):
* Components > Download *IAM-0.34-1-1.tar.gz* file, unzip & untar and then load the image:
```
docker load -i iam_image.tar
```

## IAM enabled IRIS license
In [WRC Software Distribution](https://wrc.intersystems.com/wrc/coDistribution.csp):
* Preview > Download *InterSystems IRIS IAM Preview (Docker)* license.

**IMPORTANT** Place the downloaded license into the workshop root and rename it to `iris.key`.

## Build the image
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
docker-compose up
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

## (e). Implement REST API methods
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

## (f). Test the API
* Configure the automatically created web endpoint called `/leaderboard/api/v1` in [Web Applications](http://localhost:52773/csp/sys/sec/%25CSP.UI.Portal.Applications.WebList.zen). Set unauthenticated access and set `Webinar` temporal role.
* Load in Postman the collection in [postman/leaderboard-api.postman_collection.json](postman/leaderboard-api.postman_collection.json).
* Try these requests: `GET Player`, `GET Players`, `POST Player` y `PUT Player`.


## (g). API Manager: Basic Scenario
Now, you will build a basic scenario to manage the REST API in InterSystems API Manager (IAM).

Remember IAM can be managed using the UI or using the REST interface.

*Tip:* open a VS Code Terminal session and type the following so you can send `curl` commands to IAM.
```  
docker exec -it tools sh
```

<img src="img/scenario-basic.png">

### Add API to API Manager
* Add a **service** to which will invoke the API in IRIS.
```
curl -i -X POST --url http://iam:8001/services/ \
--data 'name=iris-leaderboard-v1-service' \
--data 'url=http://irisA:52773/leaderboard/api/v1' | jq
```
* Add a **route** that will give access to the service you have just created.
```
curl -i -X POST --url http://iam:8001/services/iris-leaderboard-v1-service/routes \
--data 'paths[]=/leaderboard' | jq
```  
* In Postman, test the `IAM - Get Player - No auth` request.
* Add Authentication by setting up the `key-auth` plugin in the service. 
```
curl -X POST http://iam:8001/services/iris-leaderboard-v1-service/plugins \
    --data "name=key-auth" | jq
```
* In Postman, test again the `IAM - Get Player - No auth` request.

### Consumers
* Create some consumers so you can authenticate to access the API.
* Create consumer `systemA`
```
curl -d "username=systemA&custom_id=SYSTEM_A" http://iam:8001/consumers/ | jq
```
* Create secret for `systemA``
```
curl -X POST http://iam:8001/consumers/systemA/key-auth -d 'key=systemAsecret' | jq
```
* In Postman, test `IAM - GET Player. Consumer SystemA` request.
* Create another consumer called `webapp`
```
curl -d "username=webapp&custom_id=WEB_APP" http://iam:8001/consumers/ | jq
```
* Create secret for `webapp`
```
curl -X POST http://iam:8001/consumers/webapp/key-auth -d 'key=webappsecret' | jq
```
* In Postman, test `IAM - GET Players - Consumer WebApp` request.

### Rate Limiting
* We can simulate some traffic using [shared/simulate.sh](shared/simulate.sh) script. In your *tools* container session type:
```
/shared/simulate.sh
```
* Add a restriction for `webapp` consumer. Limit it to 100 requests in a minute.
```
curl -X POST http://iam:8001/consumers/webapp/plugins \
    --data "name=rate-limiting" \
    --data "config.minute=100" | jq
```

### Developer Portal
* Set up the Developer Portal in IAM so developers could sign up automatically.
* Go to [IAM Portal](http://localhost:8002/default/dashboard) and `Dev Portal > Settings > Authentication Plugin=Basic, Auto Approve Access=Enable > Save Changes`
* Publish the OpenAPI specs of the REST API you have just built in [Portal IAM](http://localhost:8002/default/dashboard) and  `Dev Portal > Specs > Add Spec > "leaderboard" > Add specs`

### API credentials and developers
* Go to the [Developer Portal](http://127.0.0.1:8003/default) and click `Sign Up`.
* Logged as a developer, create your own API credential in `Create API Credential`.
* In Postman, test `IAM - Get Players - Developer` replacing the `api-key` header by the actual credential you have just created.
* Access the APIs documentation in `Documentation`.

### Auditing
* There are different ways of exposing the audit logs. For example if you have any online account with HTTP interface, you can configure a global http log plugin to push logs to your remote audit manager:
```
curl -X POST http://iam:8001/plugins/ \
    --data "name=http-log" \
    --data "config.http_endpoint=http://remote-audit-interface" \
    | jq
```

## (h). API Manager: Load Balancing Scenario
You will build a load balancing scenario between two IRIS instances with the *leaderboard* REST API.

This can be useful in case you want to spread the workload, blue-green deployment, etc.

*Tip:* open a VS Code Terminal session and type the following so you can send `curl` commands to IAM.
```  
docker exec -it tools sh
```

<img src="img/scenario-lb.png">

* Create an **upstream**
```
curl -s -X POST http://iam:8001/upstreams \
    -d name=leaderboard-lb-stream \
    | jq
```
* Add the two IRIS instances **targets** to upstream

```
curl -s -X POST http://iam:8001/upstreams/leaderboard-lb-stream/targets \
    -d target=irisA:52773 \
    -d weight=500 \
    | jq
```
```
curl -s -X POST http://iam:8001/upstreams/leaderboard-lb-stream/targets \
    -d target=irisB:52773 \
    -d weight=500 \
    | jq
```
* Add a **service** referencing the upstream
```
curl -s -X POST http://iam:8001/services/ \
    --data 'name=leaderboard-lb' \
    --data 'host=leaderboard-lb-stream' \
    --data 'path=/leaderboard/api/v1' \
    | jq
```
* Add a **route** to access the service
```
curl -s -X POST http://iam:8001/services/leaderboard-lb/routes \
    --data 'paths[]=/leaderboard-lb' \
    | jq
```
* In Postman, test the `IAM - GET Players - LB` request. Pay attention to the `Node` property in the response body.

## (i). API Manager: Route by Header Scenario
You will now build a route by header scenario using three IRIS instances with the *leaderboard* REST API.

This could be useful in case you want use different servers depending on request headers (e.g. different versions).

*Tip:* open a VS Code Terminal session and type the following so you can send `curl` commands to IAM.
```  
docker exec -it tools sh
```

<img src="img/scenario-route-by-header.png">

* Create Default, V1 and V2 **upstreams**

```
curl -s -X POST http://iam:8001/upstreams \
    -d name=leaderboard-header-stream \
    | jq
```
```
curl -s -X POST http://iam:8001/upstreams \
    -d name=leaderboard-header-v1-stream \
    | jq
```
```
curl -s -X POST http://iam:8001/upstreams \
    -d name=leaderboard-header-v2-stream \
    | jq
```

* Add **targets** to each IRIS instance

```
curl -s -X POST http://iam:8001/upstreams/leaderboard-header-stream/targets \
    -d target=irisA:52773 \
    | jq
```
```
curl -s -X POST http://iam:8001/upstreams/leaderboard-header-v1-stream/targets \
    -d target=irisB:52773 \
    | jq
```
```
curl -s -X POST http://iam:8001/upstreams/leaderboard-header-v2-stream/targets \
    -d target=irisC:52773 \
    | jq
```

* Add a **service** referencing the default upstream:

```
curl -s -X POST http://iam:8001/services/ \
    --data 'name=leaderboard-header' \
    --data 'host=leaderboard-header-stream' \
    --data 'path=/leaderboard/api/v1' \
    | jq
```

* Add a **route** to access your service:
```
curl -s -X POST http://iam:8001/services/leaderboard-header/routes \
    --data 'paths[]=/leaderboard-header' \
    | jq
```

* Add `route-by-header` plugin with some conditions on request header `version`:

```
curl -s -X POST http://iam:8001/services/leaderboard-header/plugins \
    -H 'Content-Type: application/json' \
    -d '{"name": "route-by-header", "config": {"rules":[{"condition": {"version":"v1"}, "upstream_name": "leaderboard-header-v1-stream"}, {"condition": {"version":"v2"}, "upstream_name": "leaderboard-header-v2-stream"}]}}' \
    | jq
```

* In Postman, try the `IAM - GET Players - Route By Header` using different `version` header request values.
