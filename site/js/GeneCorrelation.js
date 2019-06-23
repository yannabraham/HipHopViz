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
                .text(geneID+' could not be found; please go back and check your entry')
                .style('color','red')
                .style('font-weight','bold');
    } else {
	//      start with the scatter plot
	//      define dimensions
	    var container_dimensions = { width: 1000, height: 450},
	        margins = { top: 10, right: 25, bottom: 50, left: 50},
	        chart_dimensions = {
	                width: container_dimensions.width-margins.left-margins.right,
	                height: container_dimensions.height-margins.top-margins.bottom
	        };
	    
	//      create container inside <div>
	    d3.select('#HIPHOP')
	        .append('svg')
	            .attr('width',container_dimensions.width)
	            .attr('height',container_dimensions.height);
	    
	//      define a brush to the container
	    var brush = d3.svg.brush()
	        .on("brushstart", brushstart)
	        .on("brush", brush)
	        .on("brushend", brushend);
	    
	//      compute & create axis
	    data.sort(function(a,b) { return d3.ascending(a.Correlation,b.Correlation)})
	    
	    var x_extent = [],
	    	ticks = [1];
	    
	    for(var i=1; i<=data.length; i++) {
	    	x_extent.push(i)
	    	if(Math.round(i/100)==i/100 && i<(data.length-100)) {
	    		ticks.push(i)
	    	}
	    };
	    x_extent.push(data.length+1)
	    ticks.push(data.length)
	    
	    var x_scale = d3.scale.ordinal()
	        .rangePoints([margins.left,chart_dimensions.width])
	        .domain(x_extent);
	    
	    var x_axis = d3.svg.axis().scale(x_scale)
	//    	.tickFormat(function(d) { return '' } )
	    	.tickValues(ticks);
	    
	    var y_scale = d3.scale.linear()
	        .range([chart_dimensions.height,margins.top])
	        .domain([-1,1]);
	    
	    var y_axis = d3.svg.axis().scale(y_scale).orient('left');
	    
	//      create chart
	    var chart = d3.select('svg')
		    .append('g')
		    	.attr('class','chart');
	
		chart.append('g')
		    .attr('class','x axis')
		    .attr('transform','translate(0,' + chart_dimensions.height + ')')
		    .call(x_axis)
		    .append('text')
		        .text('Rank')
		        .attr('x',margins.left+chart_dimensions.width/2)
		        .attr('y',margins.top*3);
		
		chart.append('g')
		    .attr('class','y axis')
		    .attr('transform','translate('+margins.left+',0)')
		    .call(y_axis)
		    .append('text')
		        .text('Correlation')
		        .attr('transform','rotate(-90,'+-margins.left/1.5+',0) translate('+(-6*margins.top-chart_dimensions.height/2)+')');
	
		chart.call(brush.x(x_scale).y(y_scale));
		
	    chart.selectAll('circle')
		    .data(data)
		    .enter()
		    .append('circle')
		        .attr('class',correlationType)
		        .attr('id',function(d) { return d.Systematic_name2 })
		        .attr('cx',function(d,i) { return x_scale(i+1)})
		        .attr('cy',function(d) { return y_scale(d.Correlation)})
		        .attr('r',3)
		        .on('mouseover',function(d) {
	                    d3.select(this)
	                        .transition()
	                        .attr('r',5);
	//	                    show_data(d); // too unstable for now
	                })
	            .on('mouseout', function(d) {
	                    d3.select(this)
	                        .transition()
	                        .attr('r',3);
	//	                    hide_data(); // too unstable for now
	                })
	            .on('mouseover.tooltip',function(d,i) {
	            		d3.select('text#id'+d.Systematic_name2).remove();
	                    chart.append('text')
	                        .text(d.Common_name2)
	                        .attr('x',x_scale(i+1)+10)
	                        .attr('y',y_scale(d.Correlation)+5)
	                        .attr('id','id'+d.Systematic_name2);
	                })
	            .on('mouseout.tooltip',function(d) {
	                    d3.select('text#id'+d.Systematic_name2)
	                        .transition()
	                        .duration(500)
	                        .style('opacity',0)
	                        .remove();
	                });
	    
	//      create & fill table
	//      define table, thead, tbody
	    var table = d3.select("#HIPHOPTable").select("table"),
	        thead = table.select("thead"),
	        tbody = table.select("tbody");
	    
	    thead.on('click',hide_data); // cheap trick...
	    
	//      create a row for each object in the data
	    var rows = tbody.selectAll("tr")
	        .data(data)
	        .enter()
	        .append("tr")
	            .style('display','none') // keep them hidden for now
	            .attr('id',function(d) { return d.SystematicName2 })
	            .attr('class','correlation')
	            .on('click',function(d) { window.open('../profile/gene?ID='+d.Systematic_name2); })
	            .on('mouseover',function() { d3.select(this).style('background-color','lightgrey'); } )
	            .on('mouseout',function() { d3.select(this).style('background-color',null); } );
	      
	//    create a cell in each row for each column
	    var columns = ['Systematic_name2','Common_name2','Correlation','Viability2']
	    
	    var cells = rows.selectAll("td")
	        .data(function(row) {
	            return columns.map(function(column) {
	            	var val;
	            	if(['Correlation','Min_Z_Score_1_2'].indexOf(column)>=0) {
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
	    
	    rows.sort(function(a,b) { return d3.descending(a.Correlation,b.geneID)});
    }
//    define brush functions
    function brushstart(p) {
        // make sure the table is hidden
        hide_data();
        
        if(brush.data !== p) {
            chart.call(brush.clear());
            brush.x(x_scale).y(y_scale).data = p;
        }
    }

    // not used for now
    function brush() {

    }

    // grey out the circles outside the selection, show data for the others
    function brushend() {
        if (brush.empty()) {
            chart.call(brush.clear());
            chart.selectAll('circle')
                .style('fill',null);

            hide_data();
        } else {
            var e = brush.extent(); // extent is [[X0,Y0],[X1,Y1]]
            chart.selectAll("circle")
                .style('fill','grey')
                .filter(function(d,i) { return x_scale(i+1) >= e[0][0] && x_scale(i+1) <= e[1][0] && d.Correlation >= e[0][1] && d.Correlation <= e[1][1] } )
                .style('fill',null)
                .each(show_data);
        }
    }

    function show_data(c) {
        var geneid = c.Systematic_name2;
        
        // show header
        thead.style('display','table-header-group');
        
        // show the corresponding table rows...
        tbody.selectAll('tr')
            .filter(function(d) { return d.Systematic_name2==geneid } )
            .style('display','table-row');

    }
    
    function hide_data(c) {
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