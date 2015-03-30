xquery version "1.0-ml";

import module namespace render-view = "http://render-view" at "/server/view/render-view.xqy";


  let $db-options := for $db in xdmp:database-name(xdmp:databases())
                        where  fn:not(fn:contains($db, "Security"))
                            and fn:not(fn:contains($db, "Modules"))
                            and fn:not(fn:contains($db, "Trigger"))
                            and fn:not(fn:contains($db, "JUnit"))
                       order by $db ascending
                     return 
                        if ($db = "Documents") 
                        then  <option selected="selected">{$db}</option>
                        else  <option>{$db}</option>
                     
  return  render-view:display("Upload XML File",
        <div id="stylized" class="myform grid-40 prefix-30 suffix-30 mobile-prefix-10 mobile-grid-80 mobile-suffix-10">
          <h1>XML File Upload</h1>
          
          <div id="logincontainer">
          <form name ="sendRequestForm" id="sendRequestForm" action="/upload-file" method="post" enctype="multipart/form-data">
          <dl>
                <dt><label for="uri">URI:</label></dt>
                <dd>
                    <input name="uri" type="uri" id="uri" size="30" />
                    <br/>
                </dd>
                <dt><label for="filename">File:</label><br/></dt>
                    
                <dd><input name="filename" type="file" size="30" />
                <br/>
                </dd>
                <dt><label for="uri">Database:</label></dt>
                <dd>
                    <select name="database">
                         {$db-options}
                    </select>
                    <br/>
                </dd>
            </dl>
            <div class="submitrow">
                <input class="makebutton" id="filebutton" type="submit" value="Upload" title="Upload"/>
            </div>
          </form>
          </div>
        </div>)  


