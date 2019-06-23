var charts, table, thead, tbody, x_scale, y_scale;

function draw(data) {
    "use strict";
    clear_log();
    if(window.navigator.appName=="Microsoft Internet Explorer") {
	  	d3.select('#log')
	  		.append('p')
	  			.text('Internet Explorer is not supported; please switch to a different browser for full functionality.')
	  				.style('color','red')
  					.style('font-weight','bold');
    };
    if(data==null) {
    	d3.select('#log')
            .append('p')
                .text(base+' '+ID+' could not be found; please go back and check your entry')
                .style('color','red')
                .style('font-weight','bold');
    } else {
	//      start with the scatter plot
	//      define dimensions
	    var container_dimensions = { width: 1000, height: 450},
	        margins = { top: 10, right: 25, bottom: 50, left: 50},
	        chart_dimensions = {
	                width: container_dimensions.width/2-margins.left-margins.right,
	                height: container_dimensions.height-margins.top-margins.bottom
	        };
	    
	    var types = ['HIP','HOP']
	    
	//      create container inside <div>
	    var hipHOP_container = d3.select('#HIPHOP')
	        .append('svg')
	            .attr('width',container_dimensions.width)
	            .attr('height',container_dimensions.height);
	    
	//      define a brush to the container
	    var brush = d3.svg.brush()
	        .on("brushstart", brushstart)
	        .on("brush", brush)
	        .on("brushend", brushend);
	    
	//      compute & create axis
	    var x_extent = d3.extent(data,function(d) { return d.z_score });
	    
	    x_scale = d3.scale.linear()
	        .range([margins.left,chart_dimensions.width])
	        .domain(x_extent)
	        .nice();
	    
	    var y_extent = d3.extent(data,function(d) { return d.madl_score });
	    
	    y_scale = d3.scale.linear()
	        .range([chart_dimensions.height,margins.top])
	        .domain(y_extent)
	        .nice();
	    
	    var x_axis = d3.svg.axis().scale(x_scale);
	    var y_axis = d3.svg.axis().scale(y_scale).orient('left');
	    
	//      create individual charts
	    charts = d3.select('svg')
	        .selectAll('g.chart')
	        .data(types)
	        .enter()
	        .append('g')
	        .attr('transform',function(d) {
	            if(d=='HIP') {
	                return 'translate('+margins.left+','+margins.top+')';
	            } else {
	                return 'translate('+(margins.left+chart_dimensions.width+margins.right)+','+margins.top+')';
	            }
	        })
	        .attr('id',function(d) { return d; } )
	        .attr('class','chart')
	        .each(plot);
	    
	    d3.selectAll('.x.axis')
	        .append('text')
	            .text('z-score')
	            .attr('x',margins.left+chart_dimensions.width/3)
	            .attr('y',margins.top*3);
	    
	    d3.selectAll('.y.axis')
	        .append('text')
	            .text('sensitivity score')
	            .attr('transform','rotate(-90,'+-margins.left/1.5+',0) translate('+(-6*margins.top-chart_dimensions.height/2)+')');
	    
	//      create & fill table
	//      define table, thead, tbody
	    table = d3.select("#HIPHOPTable").select("table"),
	        thead = table.select("thead"),
	        tbody = table.select("tbody");
	    
	    thead.on('click',hide_data); // cheap trick...
	    
	//      create a row for each object in the data
	    var rows = tbody.selectAll("tr")
	        .data(data)
	        .enter()
	        .append("tr")
	            .style('display','none') // keep them hidden for now
	            .attr('id',function(d) { return d[baseCol] })
	            .attr('class',function(d) { return d.type })
	            .on('click',function(d) { window.open('../profile/'+dest+'?ID='+d[destCol]); })
	            .on('mouseover',function() { d3.select(this).style('font-weight','bold'); } )
	            .on('mouseout',function() { d3.select(this).style('font-weight',null); } );
	      
	//    create a cell in each row for each column
	    var columns = ['gene_id','Common_name','compound_id','compound_name','concentration','experiment','madl_score','z_score']
	    
	    var cells = rows.selectAll("td")
	        .data(function(row) {
	            return columns.map(function(column) {
	            	var val;
	            	if(['madl_score','z_score'].indexOf(column)>=0) {
	            		val = Math.round(row[column]*100)/100;
	            	} else {
	            		val = row[column];
	            	};
	                return {column: column, value: val};
	            });
	        })
	        .enter()
	        .append("td")
	            .text(function(d) { return d.value; });
	    
	    rows.sort(function(a,b) { return d3.ascending(a.geneID,b.geneID)});
    }
	//      Plot function
    function plot(p) {
        var chart = d3.select(this);
        var chartid = this.id;
        
        chart.call(brush.x(x_scale).y(y_scale))
        
        chart
            .selectAll('circle')
            .data(data.filter(function(d) { return d.type===chartid })) // data.filter(function(d) { return d.line_id === id; });
            .enter()
            .append('circle')
                .attr('class',function(d) { return d.type })
                .attr('id',function(d) { return d[baseCol] })
                .attr('cx',function(d) { return x_scale(d.z_score)})
                .attr('cy',function(d) { return y_scale(d.madl_score)})
                .attr('r',3)
	            .on('mouseover',function(d) {
	                    d3.select(this)
	                        .transition()
	                        .attr('r',5);
	                })
	            .on('mouseout', function(d) {
	                    d3.select(this)
	                        .transition()
	                        .attr('r',3);
	                })
	            .on('mouseover.tooltip',function(d) {
	                    d3.select('text#id'+d[destCol]).remove();
	                    chart.append('text')
	                        .text(d[prettyName])
	                        .attr('x',x_scale(d.z_score)+10)
	                        .attr('y',y_scale(d.madl_score)+5)
	                        .attr('id','id'+d[destCol]);
	                })
	            .on('mouseout.tooltip',function(d) {
	                    d3.select('text#id'+d[destCol])
	                        .transition()
	                        .duration(500)
	                        .style('opacity',0)
	                        .remove();
	                });
        
        chart
            .append('g')
            .attr('class','x axis')
            .attr('transform','translate(0,' + chart_dimensions.height + ')')
            .call(x_axis);

        chart
            .append('g')
            .attr('class','y axis')
            .attr('transform','translate('+margins.left+',0)')
            .call(y_axis);
    }
//  define brush functions
    function brushstart(p) {
        // make sure the table is hidden
        hide_data();
        
        if(brush.data !== p) {
            charts.call(brush.clear());
            brush.x(x_scale).y(y_scale).data = p;
        }
    }

    // not used for now
    function brush() {
    	
    }

    // grey out the circles outside the selection, show data for the others
    function brushend() {
        if (brush.empty()) {
            charts.call(brush.clear());
            charts.selectAll('circle')
                .style('fill',null);

            hide_data();
        } else {
            var e = brush.extent(); // extent is [[X0,Y0],[X1,Y1]]
            
            charts.selectAll("circle")
                .style('fill','grey')
                .filter(function(d) { return d.z_score >= e[0][0] && d.z_score <= e[1][0] && d.madl_score >= e[0][1] && d.madl_score <= e[1][1] } )
                .style('fill',null)
                .each(show_data);
        }
    }

    function show_data(c) {
        var id = c[destCol],
            type = c.type;
        
        // show header
        thead.style('display','table-header-group');
        
        // show the corresponding table rows...
        tbody.selectAll('tr')
        	.filter(function(d) { return d[destCol]==id && d.type==type }) // alternatively this one displays only rows where type and id match
            .style('display','table-row');
    }
    
    function hide_data() {
        tbody.selectAll('tr')
            .filter( function() { return this.style.display=='table-row' })
            .style('display','none');

        thead.style('display','none');
    }
    
    function print_log(txt) {
        d3.select('#log')
            .append('p')
                .text(txt);
    }
    
    function clear_log() {
        d3.select('#log')
            .selectAll('p')
            .remove();
    }
}