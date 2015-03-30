xquery version "1.0-ml";

import module namespace functx = "http://www.functx.com"
  at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace cfg = "http://www.marklogic.com/ps/lib/config"
  at "/server/lib/config.xqy";
import module namespace render-view = "http://render-view"
  at "/server/view/render-view.xqy";
import module namespace create-adhoc = "http://create-adhoc-documents"
  at "/server/controller/create-adhoc-documents.xqy";

let $type := xdmp:get-request-field("type")
let $type-label := if($type eq "query") then "Query" else "View"
let $form := 
    <form name="adhocnewquery" action="/adhocquerywizard" method="post"
          enctype="multipart/form-data">
      <h3>Upload an XML file to being the Adhoc Query Wizard</h3>    
      <p><label>XML file to upload:
      <input type="file" class="name" name="uploadedDoc" size="50"/></label></p>
      <p><input type="submit" value="{fn:concat("Create ", $type-label)}"/></p>
      <input type="hidden" name="type" value="{$type}"/>
    </form>

return render-view:display(fn:concat("Adhoc New ",$type-label), $form)