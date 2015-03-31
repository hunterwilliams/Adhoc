xquery version "1.0-ml";

import module namespace lx = "http://marklogic.com/ps/lib/xml" at "/server/lib/l-xml.xqy";
import module namespace ld = "http://marklogic.com/ps/lib/detail" at "/server/lib/l-detail.xqy";
import module namespace cfg = "http://www.marklogic.com/ps/lib/config" at "/server/lib/config.xqy";
import module namespace render-view = "http://render-view" at "/server/view/render-view.xqy";
import module namespace cu = "http://check-user" at "/server/lib/check-user.xqy" ;


declare function local:document-uri-href($uri as xs:string, $db as xs:string){
  fn:concat("/detail?uri=",$uri,"&amp;db=",$db)
};
declare function local:render-links($uri as xs:string, $db as xs:string, $docroot as xs:string) as element()*{
  for $tab in $cfg:documentsTable/docTable
  where $tab/@root eq $docroot
  return
    (<a href="/detail?uri={$uri}&amp;db={$db}&amp;type={$tab/@id}"  >{fn:string($tab/@name)}</a>,<br/>)
};
declare function local:render-attributes($element as element()) as element(div)
{
  <div>
    <table>
      {for $attribute in $element/@*
       return <tr><td><b>{fn:concat("@",$attribute/name())}</b></td><td>{$attribute/fn:string()}</td></tr>
       }
    </table>
   </div>
};

declare function local:render-display($node) {
    typeswitch($node)
        case text() return <span class="value">{$node}</span>
        case element() 
          return 
            if (fn:exists($node/text())) then 
              <div class="element">
                <span class="element-label">{lx:label-from-element-name($node/name())}</span>
                {local:recurse($node)}
              </div>
            else if (fn:string-length($node/string()) > 0) then (:element with no direct content :)
               <div class="element-heading">
                <span class="element-label">{lx:label-from-element-name($node/name())}</span>
                {local:recurse($node)}
               </div>
            else ()
        case attribute() return <div class="attribute"><span class="attribute-name">{fn:concat("@",$node/name())}</span><span class="attribute-value">{$node/fn:string()}</span></div>
        default return local:recurse($node)
};
declare function local:recurse($node) {
    for $child in ($node/node(),$node/@*)
    return
        local:render-display($child)
};

declare function local:xdmpEval($qryStr as xs:string, $param as item()*, $db as xs:string)
{
  xdmp:eval(
    $qryStr,
    $param,
    <options xmlns="xdmp:eval">
       <database>{  xdmp:database(  $db  )}</database>
    </options>
  )
};

declare function local:show-related-items($doc,$db){
  let $results := try { ld:find-related-items-by-document($doc,$db) } catch($exception) { map:map() }
  return
      if (fn:count(map:keys($results)) = 0) then
        <h5>There are no related items</h5>
      else
        <div class="panel-group" id="accordion" role="tablist" aria-multiselectable="true">
        {
          for $key in map:keys($results)
          let $headingKey := fn:concat("heading",$key)
          let $htmlKey := fn:concat("tab",$key)
          return 
            <div class="panel panel-default">
              <div class="panel-heading" role="tab" id="{$headingKey}">
                <h4 class="panel-title">
                  <a data-toggle="collapse" data-parent="#accordion" href="#{$htmlKey}" aria-expanded="true" aria-controls="{$htmlKey}">
                    {$key} - ({fn:count(map:get($results,$key))})
                  </a>
                </h4>
              </div>
            
            <div id="{$htmlKey}" class="panel-collapse collapse" role="tabpanel" aria-labelledby="{$headingKey}">
              <div class="panel-body">
                <ol>
                  {for $uri in map:get($results,$key)
                    return <li><a href="{local:document-uri-href($uri,$db)}">{$uri}</a></li>
                  }
                </ol>
              </div>
            </div>
            </div>
          (:<a href="{local:document-uri-href($result,$db)}">{$result}</a>:)
          (:return <tr><td>{$result/type}</td><td><a href="/detail?uri={$result/uri}&amp;db={$db}">{$result/uri}</a></td><td>{$result/id}</td></tr>:)
        }
        </div>
        
};

declare function local:show-related-audits($uri){
  let $results := ld:find-related-audits-by-uri($uri)
  return
      if (fn:count($results) = 0) then
        <h5>There are no related audits</h5>
      else
        <table class="table">
        <tr><th>Database</th><th>Uri</th><th>Type</th><th>Timestamp</th><th>Collection</th></tr>
        {
          for $result in $results
          return 
            <tr>
              <td>{$result/database}</td>
              <td><a href="/detail?uri={$result/uri}&amp;db=Cleanup-Audit">{$result/uri}</a></td>
              <td>{$result/type}</td>
              <td>{$result/timestamp}</td>
              <td>{$result/collection}</td>
            </tr>
        }
        </table>
        
};

declare function local:show-collections($uri, $db) as element()*{
  let $collections := ld:get-collections($uri,$db)
  let $collection-labels := 
    for $c in $collections
    return <span class="label label-success label-collection">{$c}</span>
  return 
    if (fn:count($collections) = 0) then
      <div class="alert alert-info" role="alert">
        Not in any collections
      </div>
    else
      $collection-labels
};

declare function local:show-permissions($uri,$db) as element()*{
  let $permissions := ld:get-permissions($uri,$db)
  let $perm-labels := 
    for $perm in $permissions
    return <span class="label label-warning label-permission">{fn:concat($perm/role-name,":",$perm/capability)}</span>
  return 
    if (fn:count($permissions) = 0) then
      <div class="alert alert-warning" role="alert">
        <strong>Warning!</strong> Admin Only Permissions
      </div>
    else
      $perm-labels
};

declare function local:buildTable($uri,$db,$docroot,$type)
{
let $doctbl :=
   for $t in $cfg:documentsTable/docTable
   where $t/@root eq $docroot and $t/@id eq $type
   return $t
let $quote := """"
let $docuristr := "fn:doc(" || $quote ||  $uri || $quote || ")" || $doctbl/base/@xpath
let $_ := xdmp:log( $docuristr )
let $qrystr :=
'
<table border="1"  id="results">
'
||
xdmp:quote(<thead>{for $fld in $doctbl/field return <th>{$fld/fn:string()}</th>}</thead>)
||
'
{
for $i in '
||

$docuristr || '
return '

||

xdmp:quote(
<tbody><tr>{for $fld in $doctbl/field return <td>{{$i/{fn:string($fld/@xpath)}}}</td>}</tr></tbody>
)

||

'
}
</table>'
return local:xdmpEval($qrystr,(),$db)


};

(: -------------------------------------------------------------------------------------  :)
(:                                   main                                                                                                                                                                       :)
(: -------------------------------------------------------------------------------------  :)
let $uri := xdmp:get-request-field("uri")
let $db := xdmp:get-request-field("db")
let $type := xdmp:get-request-field("type","details")

let $doc :=  ld:get-document($uri,$db)/element()
let $docroot := fn:local-name( $doc )
let $links := local:render-links($uri,$db,$docroot)
let $searchText := ""
return
  if ( $type = "details" ) then
    let $html := 
      <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
          <meta http-equiv="Content-Style-Type" content="text/css"></meta>
          <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"></meta>
          <meta name="viewport" content="width=device-width, initial-scale=1"></meta>
          <title>Document View: {$uri}</title>

          <link rel="stylesheet" href="/css/bootstrap.min.css" />
          <link rel="stylesheet" href="/css/detail.css" />

          <script type="text/javascript" src="/js/jquery-1.11.2.min.js"></script>
          <script type="text/javascript" src="/js/bootstrap.min.js"></script>
          <script type="text/javascript" src="/js/vkbeautify.0.99.00.beta.js"></script>
          <script type="text/javascript" src="/js/detail.js"></script>
        </head>
        <body>
          <div class="document-header">{fn:concat($docroot," - ",$uri)}</div>
          <a href="/adhocquery"><span class="glyphicon glyphicon-home home"></span></a>
          <div class="container-fluid">
            <div class="row">
              <div class="col-md-7">
                <div role="tabpanel">

                  <!-- Nav tabs -->
                  <ul class="nav nav-tabs" role="tablist">
                    <li role="presentation" class="active"><a href="#data-view" aria-controls="data-view" role="tab" data-toggle="tab">Data View</a></li>
                    <li role="presentation"><a href="#xml-view" aria-controls="xml-view" role="tab" data-toggle="tab">XML View</a></li>
                  </ul>

                  <!-- Tab panes -->
                  <div class="tab-content">
                    <div role="tabpanel" class="tab-pane active" id="data-view">
                      <div id="details">
                        <br/>                         
                        <br/>
                        <div id="detailTab">
                        {
                          let $highlight-doc := local:render-display($doc) (:cts:highlight(local:render-display($doc), $searchText, <span style="background:yellow">{$cts:text}</span>):)
                          return
                              $highlight-doc
                        }
                        </div>
                      </div>
                    </div>
                    <div role="tabpanel" class="tab-pane" id="xml-view">
                    <br/>
                    <a class="btn btn-default xml-button" href="/detail?uri={$uri}&amp;db={$db}&amp;type=xml" role="button">
                      <span class="glyphicon glyphicon-share" aria-hidden="true"></span>XML-Only Page
                    </a>
                    <br/>
                    <code id="xml-code">{xdmp:quote($doc)}</code></div>
                  </div>

                </div>
              </div>
              <div class="col-md-4">
                <div class="related-items-col">
                  <h2>Information</h2>
                  <div>
                    <div>
                      <h4>Collections</h4> {local:show-collections($uri,$db)}
                    </div>
                    { if (cu:is-admin()) then(
                        <div>
                        <h4>Permissions</h4> {local:show-permissions($uri,$db)}
                        </div>
                      ) 

                      else ()
                    }
                    <div>
                    {
                      if (fn:count($links) > 0) then
                        (<h4>Plan Links</h4>,
                          <div>
                            {$links}
                          </div>
                        )
                      else
                        ()
                    }
                    </div>
                  </div>
                </div>
                <div class="related-items-col">
                  <h2>Related Items</h2>
                  <div>
                    {local:show-related-items($doc, $db)}
                  </div>
                </div>
              </div>
            </div>
          </div>
          
        </body>
      </html>

    return 
      (
        xdmp:set-response-content-type("text/html; charset=UTF-8"),
        '<!DOCTYPE html>',
        $html
      )
    
  else if( $type eq ($cfg:documentsTable/docTable/@id/fn:string()) ) then
      (
        xdmp:set-response-content-type("text/html"),
        let $table := local:buildTable($uri,$db,$docroot,$type)
        let $data := xdmp:quote( $table )
        return
            render-view:displayTable(
               "Adhoc Query",
                <form target="_new" action="/outputs" method="post">
                {if($cfg:create-user) then <input type="submit"  value="Download" /> else ()}
                <input type="hidden" name="data" value="{$data}"/>
                <div style="overflow: auto;">
                {$table}
                </div>
                </form>
             )
      )
  else
   (
   xdmp:set-response-content-type("text/xml"),
   $doc
  )