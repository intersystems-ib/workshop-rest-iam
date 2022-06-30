# Workshop: REST and InterSystems API Manager
This repository contains the materials and some examples you can use to learn the basic concepts of REST and IAM. 

You can find more in-depth information in https://learning.intersystems.com.

# What do you need to install? 
* [Git](https://git-scm.com/downloads) 
* [Docker](https://www.docker.com/products/docker-desktop) (if you are using Windows, make sure you set your Docker installation to use "Linux containers").
* [Docker Compose](https://docs.docker.com/compose/install/)
* [Visual Studio Code](https://code.visualstudio.com/download) + [InterSystems ObjectScript VSCode Extension](https://marketplace.visualstudio.com/items?itemName=daimor.vscode-objectscript)
* [Postman](https://www.getpostman.com/downloads/)
* InterSystems IRIS IAM enabled license file.

# Setup

## Get InterSystems IRIS & IAM image
You need to setup your access to InterSystems Container Registry to download IRIS limited access images.

Have a look at this [Introducing InterSystems Container Registry](https://community.intersystems.com/post/introducing-intersystems-container-registry) on [Developer Community](https://community.intersystems.com).

* Log-in into https://containers.intersystems.com/ using your WRC credentials and get a *token*.
* Set up docker login in your computer:
```bash
docker login -u="user" -p="token" containers.intersystems.com
```
* Download images:
```bash
docker pull containers.intersystems.com/intersystems/iris:2022.1.0.209.0
docker pull containers.intersystems.com/intersystems/iam:2.3.3.2-1
```

## IAM enabled IRIS license
**IMPORTANT!** Copy your InterSystems IRIS IAM enabled license file into the workshop root and rename it to `iris.key`.

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
```bash
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
```console
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
```objectscript
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
```objectscript
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
    			"Alias": (rs.%Get("Alias")),
    			"Node": ($system.INetInfo.LocalHostName())
    		})
    }
    
    quit array
}
```

### getPlayerById
```objectscript
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
```objectscript
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
```objectscript
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
* In Postman, import [postman/leaderboard-api.postman_collection.json](postman/leaderboard-api.postman_collection.json) collection.
* Try these requests: `GET Player`, `GET Players`, `POST Player` y `PUT Player`.

## (g). Make your REST API part of an interoperability production (optional)

You'll plug the API implementation into a production, so you could use any feature of interoperability productions withing a REST API implementation.

### Create production and add a dummy BO
* Using the [Management Portal](http://localhost:52773/csp/sys/%25CSP.Portal.Home.zen?$NAMESPACE=WEBINAR) *Interoperability > List > Productions > New*, create a new production called `Webinar.Production`.
* Click on `Production Settings` and in *Settings* tab make sure `Testing enabled` is checked.
* Let's create a simple Business Operation that you will use to request some information you will include in your REST API response. This component sends a REST message to an external dummy service and returns a value. Have a look at the source code [src/Webinar/BO/DummyREST.cls](src/Webinar/BO/DummyREST.cls)
* Add a new Business Operation in your production, choose `Webinar.BO.DummyREST`. Then, in the *Settings* tab configure:
  * *HTTP Server:* `mockbin.com`
  * *URL:* `/request`
* Test the Business Operation in the *Actions* tab clicking on the Test button.

### Make your REST API a Business Service
* In VS Code, open your REST API implementation [src/Webinar/API/Leaderboard/v1/impl.cls](src/Webinar/API/Leaderboard/v1/impl.cls).
* Update the class to extends from `(%REST.Impl, Ens.BusinessService)`. Now, you have turned your REST API into a Business Service.
* In the [Webinar.Production](http://localhost:52773/csp/webinar/EnsPortal.ProductionConfig.zen?PRODUCTION=Webinar.Production) production configuration page, add a new Business Service and select `Webinar.API.Leaderboard.v1.impl`. Keep it disabled.
* Back in VS Code, change the [src/Webinar/API/Leaderboard/v1/impl.cls](src/Webinar/API/Leaderboard/v1/impl.cls) `getPlayerById` implementation:
```objectscript
ClassMethod getPlayerById(playerId As %Integer) As %DynamicObject
{
    set player = ##class(Webinar.Data.Player).%OpenId(playerId)
    if '$isobject(player) {
    	do ..%SetStatusCode(404)
    	quit ""
    }

    // instantiate Business Service (interoperability framework)
    set sc = ##class(Ens.Director).CreateBusinessService("Webinar.API.Leaderboard.v1.impl",.service)
    $$$ThrowOnError(sc)

    // build request message
    set req = ##class(Ens.StringContainer).%New()
    set req.StringValue = playerId
        
    // send message to Business Operation
    set sc = service.SendRequestSync("Webinar.BO.DummyREST", req, .rsp)
    $$$ThrowOnError(sc)

    // concatenate Business Operation response to REST API response
    set player.Name = player.Name_"("_rsp.StringValue_")"

    do player.%JSONExportToStream(.stream)
    quit stream
}
```
* Enable the `Webinar.API.Leaderboard.v1.impl` Business Service in production configuration page.
* In Postman, test the `GET Player` request and check [Message Viewer](http://localhost:52773/csp/webinar/EnsPortal.MessageViewer.zen?SOURCEORTARGET=Webinar.API.Leaderboard.v1.impl) messages and visual trace.
* **IMPORTANT!** In order to continue the next sections, stop the production and revert the changes on [src/Webinar/API/Leaderboard/v1/impl.cls](src/Webinar/API/Leaderboard/v1/impl.cls) `getPlayerById` to continue. Test again the `GET Player` request in Postman and check it's OK.


## (h). API Manager: Basic Scenario
Now, you will build a basic scenario to manage the REST API in InterSystems API Manager (IAM).

Remember IAM can be managed using the UI or using the REST interface.

*Tip:* open a VS Code Terminal session and type the following so you can send `curl` commands to IAM.
```bash  
docker exec -it tools sh
```

<img src="img/scenario-basic.png">

### Add API to API Manager
* Add a **service** to which will invoke the API in IRIS.
```bash
curl -X POST --url http://iam:8001/services/ \
--data 'name=iris-leaderboard-service' \
--data 'url=http://irisA:52773/leaderboard/api/v1' | jq
```
* Add some **routes** that will give access to the service you have just created.

```bash
curl -X POST --url http://iam:8001/services/iris-leaderboard-service/routes \
--data 'paths[]=/leaderboard' \
--data 'name=leaderboard-GET' \
--data 'methods[]=GET'| jq
```

```bash
curl -X POST --url http://iam:8001/services/iris-leaderboard-service/routes \
--data 'paths[]=/leaderboard' \
--data 'name=leaderboard-POST' \
--data 'methods[]=POST'| jq
```

```bash
curl -X POST --url http://iam:8001/services/iris-leaderboard-service/routes \
--data 'paths[]=/leaderboard' \
--data 'name=leaderboard-PUT' \
--data 'methods[]=PUT'| jq
```

#### Add request transformer plugin to service
* Using the request-transformer plugin you can add Basic authentication headers to incoming requests so it will authenticate in IRIS.

```bash
curl -i -X POST \
--url http://iam:8001/services/iris-leaderboard-service/plugins \
--data 'name=request-transformer' \
--data 'config.add.headers=Authorization:Basic c3VwZXJ1c2VyOlNZUw==' \
--data 'config.replace.headers=Authorization:Basic c3VwZXJ1c2VyOlNZUw=='
```

* In Postman, test the `IAM - Get Player - No auth` request.

### Enable authentication (key-auth)
* Add Authentication by setting up the `key-auth` plugin in the service. 
```bash
curl -X POST http://iam:8001/services/iris-leaderboard-service/plugins \
--data "name=key-auth" | jq
```
* In Postman, test again the `IAM - Get Player - No auth` request.

### Consumers
* Create some consumers so you can authenticate to access the API.
* Create consumer `systemA`
```bash
curl -d "username=systemA&custom_id=SYSTEM_A" http://iam:8001/consumers/ | jq
```
* Create secret for `systemA``
```bash
curl -X POST http://iam:8001/consumers/systemA/key-auth -d 'key=systemAsecret' | jq
```
* In Postman, test `IAM - GET Player. Consumer SystemA` request.
* Create another consumer called `webapp`
```bash
curl -d "username=webapp&custom_id=WEB_APP" http://iam:8001/consumers/ | jq
```
* Create secret for `webapp`
```bash
curl -X POST http://iam:8001/consumers/webapp/key-auth -d 'key=webappsecret' | jq
```
* In Postman, test `IAM - GET Players - Consumer WebApp` request.

### Rate Limiting 
* We can simulate some traffic using [shared/simulate.sh](shared/simulate.sh) script in your *tools* container:
```bash  
docker exec -it tools sh
/shared/simulate.sh
```
* Add a restriction for `webapp` consumer. Limit it to 100 requests in a minute.
```bash
curl -X POST http://iam:8001/consumers/webapp/plugins \
    --data "name=rate-limiting" \
    --data "config.minute=100" | jq
```
* Remove the restriction using the IAM Portal so you can continue.

### Developer Portal
* Set up the Developer Portal in IAM so developers could sign up automatically.
* Go to [IAM Portal](http://localhost:8002/default/dashboard) and `Dev Portal > Settings`:
* Set `Authentication Plugin=Basic`
* Set `Auto Approve Access=Enable`
* Set `Session Config (JSON)=Custom` and enter:
```
{
    "cookie_name": "portal_session",
    "secret": "CHANGE_THIS",
    "storage": "kong",
    "cookie_secure": false
}
``` 
* Save Changes
* Publish the OpenAPI specs of the REST API you have just built in [IAM Portal](http://localhost:8002/default/dashboard) and  `Dev Portal > Editor`
* Click on `New File +` and set `File Type=spec` and `File Path=leaderboard.yaml`.
* Copy the content of [leaderboard-api-v1.yaml](shared/leaderboard-api-v1.yaml). 

### API credentials and developers
* Go to the [Developer Portal](http://127.0.0.1:8003/default) and click `Sign Up`.
* Logged as a developer, create your own API credential in `Create API Credential`.
* In Postman, test `IAM - Get Players - Developer` replacing the `api-key` header by the actual credential you have just created.
* Access the APIs documentation in `Documentation`.

### Auditing
* There are different ways of exposing the audit logs. For instance, you can configure a global http log plugin to push logs to your remote audit interface.
* In this case you can use a very simple REST audit interface that will audit IAM requests into `shared/audit.json` file.
```bash
curl -X POST http://iam:8001/plugins/ \
    --data "name=http-log" \
    --data "config.http_endpoint=http://irisA:52773/audit/log" \
    | jq
```
* Try again some IAM requests in Postman and check the audit file.


## (i). API Manager: Load Balancing Scenario
You will build a load balancing scenario between two IRIS instances with the *leaderboard* REST API.

This can be useful in case you want to spread the workload, blue-green deployment, etc.

*Tip:* open a VS Code Terminal session and type the following so you can send `curl` commands to IAM.
```bash
docker exec -it tools sh
```

<img src="img/scenario-lb.png">

* Create an **upstream**
```bash
curl -s -X POST http://iam:8001/upstreams \
    -d name=leaderboard-lb-stream \
    | jq
```
* Add the two IRIS instances **targets** to upstream

```bash
curl -s -X POST http://iam:8001/upstreams/leaderboard-lb-stream/targets \
    -d target=irisA:52773 \
    -d weight=500 \
    | jq
```
```bash
curl -s -X POST http://iam:8001/upstreams/leaderboard-lb-stream/targets \
    -d target=irisB:52773 \
    -d weight=500 \
    | jq
```

* Update your **service** to point to the upstream:
```bash
curl -X PATCH http://iam:8001/services/iris-leaderboard-service \
  --data host='leaderboard-lb-stream' | jq
```

* In Postman, test the `IAM - GET Players (LB)` request. Pay attention to the `Node` property in the response body.

## (j). API Manager: Route by Header Scenario
You will now build a route by header scenario using three IRIS instances with the *leaderboard* REST API.

This could be useful in case you want use different servers depending on request headers (e.g. different versions).

*Tip:* open a VS Code Terminal session and type the following so you can send `curl` commands to IAM.
``` bash
docker exec -it tools sh
```

<img src="img/scenario-route-by-header.png">

* Create Default, V1 and V2 **upstreams**

```bash
curl -s -X POST http://iam:8001/upstreams \
    -d name=leaderboard-header-stream \
    | jq
```
```bash
curl -s -X POST http://iam:8001/upstreams \
    -d name=leaderboard-header-v1-stream \
    | jq
```
```bash
curl -s -X POST http://iam:8001/upstreams \
    -d name=leaderboard-header-v2-stream \
    | jq
```

* Add **targets** to each IRIS instance

```bash
curl -s -X POST http://iam:8001/upstreams/leaderboard-header-stream/targets \
    -d target=irisA:52773 \
    | jq
```
```bash
curl -s -X POST http://iam:8001/upstreams/leaderboard-header-v1-stream/targets \
    -d target=irisB:52773 \
    | jq
```
```bash
curl -s -X POST http://iam:8001/upstreams/leaderboard-header-v2-stream/targets \
    -d target=irisC:52773 \
    | jq
```

* Update your **service** to point to the upstream:
```bash
curl -X PATCH http://iam:8001/services/iris-leaderboard-service \
  --data host='leaderboard-header-stream' | jq
```

* Add `route-by-header` plugin with some conditions on request header `version`:

```bash
curl -s -X POST http://iam:8001/services/iris-leaderboard-service/plugins \
    -H 'Content-Type: application/json' \
    -d '{"name": "route-by-header", "config": {"rules":[{"condition": {"version":"v1"}, "upstream_name": "leaderboard-header-v1-stream"}, {"condition": {"version":"v2"}, "upstream_name": "leaderboard-header-v2-stream"}]}}' \
    | jq
```

* In Postman, try the `IAM - GET Players (Route By Header)` using different `version` header request values.

## (j). DeCK

decK helps manage Kong’s configuration in a declarative fashion. This means that a developer can define the desired state of Kong Gateway – services, routes, plugins, and more – and let decK handle implementation without needing to execute each step manually, as you would with the Kong Admin API.

https://docs.konghq.com/deck/1.12.x/

* Open a interactive session with tools container in order to install and run deCK

``` bash
docker exec -it tools sh
```

* Install decK in the tools container:
```bash
cd /tmp
curl -sL https://github.com/kong/deck/releases/download/v1.12.2/deck_1.12.2_linux_amd64.tar.gz -o deck.tar.gz
tar -xf deck.tar.gz -C /tmp
cp /tmp/deck /usr/local/bin/
```

* Backup. Run decK to create a backup of the configuration you have just made:
```bash
deck dump --kong-addr http://iam:8001
```

Now have a look at the file `kong.yaml`.

* Restore (dry-run). You can run diff to show a dry-run of the changes that will be loaded into IAM:
```
deck diff --kong-addr http://iam:8001
``` 

* Restore. To load the changes you have exported previously into `kong.yaml` run the following:
```
deck sync --kong-addr http://iam:8001
```

# Explore other scenarios
Have a look at this example where you can see in action a REST API in IRIS as backend for an Angular application:
https://github.com/intersystems-ib/iris-sample-rest-angular
