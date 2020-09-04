Class Webinar.BO.DummyREST Extends EnsLib.REST.Operation
{

Parameter INVOCATION = "Queue";

Method sendRequest(pRequest As Ens.StringContainer, Output pResponse As Ens.StringContainer) As %Status
{
    set ret = $$$OK
    try {
        set pResponse = ##class(Ens.StringContainer).%New()

        // request URL
        set url = ..Adapter.URL
        
        // build some request body
        set body = { 
            "query": (pRequest.StringValue),
            "type": "dummy"
        }

        // send POST request to a dummy service
        set sc = ..Adapter.PostURL(url, .httpRsp, "", body.%ToJSON())
		if $$$ISERR(sc),$isobject(httpRsp),$isobject(httpRsp.Data),httpRsp.Data.Size {
            return $$$ERROR($$$EnsErrGeneral,$$$StatusDisplayString(sc)_":"_httpRsp.Data.Read())
        }
        $$$ThrowOnError(sc)
        
        // handle response
        if $isobject(httpRsp) {
            // instantiate response in json dynamic object
            set jsonRsp = {}.%FromJSON(httpRsp.Data.Read())
            
            // show response
            $$$LOGINFO(jsonRsp.%ToJSON())
            
            // retrieve some field into response
            set pResponse.StringValue = jsonRsp.clientIPAddress
        }

   } catch ex {
       set ret = ex.AsStatus()
   }
   quit ret
}

XData MessageMap
{
<MapItems>
  <MapItem MessageType="Ens.StringContainer">
    <Method>sendRequest</Method>
  </MapItem>
</MapItems>
}

}
