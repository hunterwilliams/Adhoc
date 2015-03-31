xquery version "1.0-ml";

import module namespace cw = "http://model/copy-workspace" at "/model/copy-workspace.xqy";

import module namespace rest="http://marklogic.com/appservices/rest" at "/MarkLogic/appservices/utils/rest.xqy";
import module namespace endpoints="http://example.com/ns/endpoints" at "/server/lib/endpoints.xqy";
import module namespace render-view = "http://render-view" at "/server/view/render-view.xqy";

declare variable $params as map:map := rest:process-request(endpoints:request($endpoints:COPY-WORKSPACE));

let $workspace := map:get($params, "workspace") 
return 
    let $uri := cw:copy-workspace($workspace)
    let $message := 
        if (fn:contains($uri, "/workspaces/") and fn:contains($uri, ".xml"))
        then (render-view:display("Workspace Imported", 
                                    <div><h1>Workspace Imported</h1>
                                    <p>Workspace has been imported to your user account.</p></div>))
        else (render-view:display("Import Failed", 
                                    <div><h1>Import Failed</h1>
                                    <p>Workspace was not imported.</p></div>))
    return $message