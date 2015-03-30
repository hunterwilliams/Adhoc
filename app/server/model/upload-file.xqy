xquery version "1.0-ml";

import module namespace render-view = "http://render-view" at "/server/view/render-view.xqy";

declare function local:insert-to-db($uri, $node, $db as xs:string) {
      ($uri, $node, xdmp:eval('
        declare variable $uri as xs:string external;
        declare variable $node as node() external;

        xdmp:document-insert($uri, $node)
        ', 
        (xs:QName("uri"),  $uri, xs:QName("node"), $node ),
        <options xmlns="xdmp:eval">
          <database>{xdmp:database($db)}</database>
        </options>
      ))
};

let $file := xdmp:get-request-field( "filename")
let $uri := xdmp:get-request-field( "uri" )
let $db := xdmp:get-request-field( "database" )
let $filename := xdmp:get-request-field-filename("filename")
let $isXml := fn:ends-with($filename, "xml")
let $check-file :=
        if ($file and $uri and $db and $isXml) 
        then ()
        else ()
let $_ := local:insert-to-db($uri, xdmp:unquote($file), $db) 
       
return
   render-view:display("File Uploaded", <div><h1>File Uploaded</h1><p>The selected file has been uploaded.</p><a class="makebutton" href="/file-upload-form">Upload XML to Database</a></div>)
  