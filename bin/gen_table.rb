#!/usr/local/bin/ruby
require_relative '../rlib/configuration.rb'
require 'pp'

@config = Configuration.new("#{File.dirname(__FILE__)}/../conf/rack_master.json")

cols = 21
rows = 30
cc = 0
cr = 0

File.open('../web/heatmap3.html', 'w') do |fd|
fd.puts <<-EOF
<html>
<head>
<title>CPU Usage</title>
<meta name="robots" content="noindex,nofollow" />
<meta name="description" content="Pan Cluster Management IPV4 Ping State" />

<script> var ping_target='heatmap';
         var state_file='/cgi-bin/noheader/heatmapjson.cgi';
         var ignore_file='ignore.json';
         var page_header='Pan Heatmap';
</script>

<script src="/rgraph/libraries/RGraph.common.core.js" ></script>
<script src="/rgraph/jquery.min.js"></script>

<style type="text/css">
table.rack {
  background-color: black;
}
table.rack td {
  border-width: 1px;
  border-style: solid;
  border-color: orange;
  padding: 0px;
  padding: 0px;
  background-color: white;
  color: white;
  font-family:sans-serif;
  font-size:10pt;
  height: 15px;
  width: 15px;
}
table.rack td.empty {
  border-width: 1px;
  border-style: solid;
  border-color: black;
  padding: 0px;
  padding: 0px;
  background-color: black;
  color: white;
  font-family:sans-serif;
  font-size:10pt;
  height: 15px;
  width: 15px;
}
table.rack th {
  border-width: 1px;
  border-style: solid;
  border-color: white;
  padding: 0px;
  padding: 0px;
  background-color: white;
  color: black;
  font-family:sans-serif;
  font-size:10pt;
  height: 15px;
  width: 15px;
}
</style>

<script>
function set_cell(cell_id, new_state, title) {
    var the_cell = document.getElementById(cell_id);
    if(the_cell != null) {
      if(new_state != null && new_state["loadcolor"] != null) {
        the_cell.style.backgroundColor = new_state["loadcolor"];
        the_cell.style.borderColor = 'black';
        title += '\\n\\nCPUs: ' + new_state['cpus'] + '\\nCPUs Used: ' + new_state['cpusused'] + '\\n';
      }
      else {
        switch(new_state) {
          case 'no_u': //There isn't such a U in the rack
            the_cell.style.backgroundColor = 'black';
            the_cell.style.borderColor = 'black';
            the_cell.title = cell_id ;
            return;
          case 'no_state': //we know there will not be a state record
            the_cell.style.backgroundColor = 'grey';
            the_cell.style.borderColor = 'white';
            the_cell.title = cell_id ;
            return;
          case 'blank': //known filler in the rack
            the_cell.style.backgroundColor = 'black';
            the_cell.style.borderColor = 'white';
            the_cell.title = cell_id ;
            return;
          case 'ok':
            the_cell.style.backgroundColor = '#00FF00'; //green
            the_cell.style.borderColor = 'white';
            break;
          case 'degraded':
            the_cell.style.backgroundColor = 'orange';
            the_cell.style.borderColor = 'white';
            break;
          case 'fault':
            the_cell.style.backgroundColor = '#920000'; //red
            the_cell.style.borderColor = '#FF0000';
            break;
          case 'unexpected': //didn't expect there to be data
            the_cell.style.backgroundColor = '#0000FF'; //blue
            the_cell.style.borderColor = 'orange';
            break
          default: //no data, but expected it
            the_cell.style.backgroundColor = 'white';
            the_cell.style.borderColor = 'orange';
        }
      }
      the_cell.title = title + '\\n' + cell_id ;
    }
  }
  
  var delay_state = 60000; //1 minutes
        
  function myAJAXCallback_state(data) {
    var date_stamp = document.getElementById('date_stamp');
    process_each_rack(data.state);
    date_stamp.innerHTML = data.datetime.substring(0,19);
    // Make another AJAX call after the delay (which is in milliseconds)
    setTimeout(function () { RGraph.AJAX.getJSON(window.state_file + "?timestamp="+ Date.now(), myAJAXCallback_state); }, delay_state);
  }
  
  function myAJAXCallback_ignore(data) {
    for(var i=0; i < data.ignore.length; i++) {
      document.getElementById(data.ignore[i]).style.backgroundColor = 'grey';
      document.getElementById(data.ignore[i]).style.borderColor = 'black';
    }
    
    // Make another AJAX call after the delay (which is in milliseconds)
    setTimeout(function () { RGraph.AJAX.getJSON(window.ignore_file + "?timestamp="+ Date.now(), myAJAXCallback_ignore); }, delay_state);
  }

  function process_each_rack(state) {
    for(var c in state) { 
      set_cell(c, state[c], '')
    }
  }

  function init() {
  /**
  * Initial AJAX calls
  */
    var header = document.getElementById('header');
    
    setTimeout(function () { RGraph.AJAX.getJSON(window.ignore_file + "?timestamp="+ Date.now(), myAJAXCallback_ignore); }, 0);
    setTimeout(function () {RGraph.AJAX.getJSON(window.state_file + "?timestamp="+ Date.now(), myAJAXCallback_state);}, 0);
    header.innerHTML = window.page_header;
  }
</script>

</head>
<body>
<H1 id="header">XXXX State</H1>
<table id='tdc' class='rack'>
<tr><th colspan=21 align='right'>
  <select id="view1">
    <option value="cpusdeviation">CPU cores: discrepancy used vs requested</option>
    <option value="cpusreq">CPU cores: requested usage</option>
    <option value="cpusused" selected>CPU cores: actual usage</option>
    <option value="memdeviation">Memory: discrepancy used vs requested</option>
    <option value="memreq">Memory: requested usage</option>
    <option value="memused">Memory: actual usage</option>
  </select>
</th></tr>
<tr>
EOF
#   A-Rack      
[['E18','D18'],['I18','H18'],['H15','I15'],['D15','E15'],['K15','L15'],['B18','G18','G15']].each do |a| #Racks with compute nodes order A, B, C, D, E and others
  fd.puts "<td colspan=#{cols}><table class='rack'>"
  fd.puts "<tr><td>"
  a.each do |r|
    @config.rack[r]['nodes'].each do |k, node|
      if node['heatmap'] != nil && node['heatmap'] != ""
        if cc == cols
          fd.puts "</tr>"
          fd.puts "<tr>" if cr + 1 < rows
          cc = 0
          cr += 1
        end
        
        fd.puts "<td id='#{node['heatmap']}' title='#{node['heatmap']}'>&nbsp;</td>"
        cc += 1
      end
    end
  end
  (cc...cols).each do |c|
    fd.puts "<td class=empty>&nbsp;</td>"
  end
  fd.puts "</td></tr>"
  fd.puts "</table></td>" 
  cc = 0
  cr += 1
end
=begin
(cc...cols).each do |c|
  fd.puts "<td class=empty>&nbsp;</td>"
end
=end

fd.puts <<-EOF
</tr>
<tr><th colspan=#{cols} align='right' id='date_stamp'>&nbsp;</th></tr>
</table>

<script>
  init();
</script>
</body>
</html>
EOF
end



