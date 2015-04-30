xquery version "1.0-ml";
module namespace lx = "http://marklogic.com/ps/lib/xml";

(:~
	XML Utility code
	@author derickson
:)


import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";   

(: pretty print stylesheet :)
declare variable $pp-ss :=
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" indent="yes" encoding="UTF-8"/>
<xsl:template match="@*|element( )">
 <xsl:copy>
  <xsl:apply-templates select="@*|element( )|text()[ string-length(normalize-space(string(.))) gt 0 ]"/>
 </xsl:copy>
</xsl:template>
</xsl:stylesheet>;

(:~ 
	@param orig - original XML element to be pretty printed
	@return XML pretty printed with spaces and not spaces/tabs
:)
declare function lx:pretty-print($orig as element()) as element() {
  xdmp:unquote(
    fn:replace(
      xdmp:quote(
        xdmp:xslt-eval($pp-ss, $orig)/element()
      ),
      "&#09;",
      "&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;"
    )
  )/element()
};


declare function lx:change-elements-deep
  ( $nodes as node()* ,
    $oldNames as xs:QName* ,
    $newElements as element()* )  as node()* {
       
  if (fn:count($oldNames) != fn:count($newElements))
  then fn:error(xs:QName('lx:Different_number_of_names'))
  else
   for $node in $nodes
   return if ($node instance of element())
          then 
            let $newElement := $newElements[fn:index-of($oldNames, fn:node-name($node))]
            return
            element { functx:if-empty(fn:node-name($newElement),fn:node-name($node)) }
                 {
                  $node/@*,
                  $newElement/@*,
                  lx:change-elements-deep($node/node(), $oldNames, $newElements)
                 }
          else if ($node instance of document-node())
          then lx:change-elements-deep($node/node(), $oldNames, $newElements)
          else $node
 } ;
 
 
 declare function lx:label-from-element-name($element-name as xs:string?) as xs:string? {
    
    fn:string-join(
                for $word in fn:tokenize(functx:camel-case-to-words($element-name," "), "-")
                return functx:capitalize-first(functx:trim($word))
                , " ")
    
   
 };
