var chart, table, thead, tbody, x_scale, y_scale;

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
        //  start with the scatter plot
        //  define dimensions
        var container_dimensions = { width: 1000, height: 450},
            margins = { top: 10, right: 25, bottom: 50, left: 50},
            chart_dimensions = {
                    width: container_dimensions.width-margins.left-margins.right,
                    height: container_dimensions.height-margins.top-margins.bottom
        };
        //  create container inside <div>
        var hipHOP_container = d3.select('#HIPHOP')
            .append('svg')
                .attr('width',container_dimensions.width)
                .attr('height',container_dimensions.height);
        
        //  compute & create axis
        data.sort(function(a,b) { return d3.ascending(a[destCol],b[destCol])})
        
        var x_extent = data.map(function(d) {return String(d[destCol])})

        x_scale = d3.scale.ordinal()
            .rangePoints([margins.left,chart_dimensions.width])
            .domain(x_extent);
        
        var y_extent = d3.extent(data,function(d) { return d[scoreCol]; });
        
        y_scale = d3.scale.linear()
            .range([chart_dimensions.height,margins.top])
            .domain(y_extent)
            .nice();
        
        var x_axis = d3.svg.axis().scale(x_scale)
        	.tickFormat(function(d) { return '' } )
        	.tickSize(0)
        
        var y_axis = d3.svg.axis().scale(y_scale).orient('left');

        //  create profile plot
        chart = d3.select('svg')
            .append('g')
            .attr('class','chart');
        
        chart.append('g')
            .attr('class','x axis')
            .attr('transform','translate(0,' + chart_dimensions.height + ')')
            .call(x_axis)
            .append('text')
                .text(function() { if(dest=='gene') { return 'chromosome position'; } else { return dest; }; })
                .attr('x',margins.left+chart_dimensions.width/2.4)
                .attr('y',margins.top*3);

        chart.append('g')
            .attr('class','y axis')
            .attr('transform','translate('+margins.left+',0)')
            .call(y_axis)
            .append('text')
                .text(score)
                .attr('transform','rotate(-90,'+-margins.left/1.5+',0) translate('+(-6*margins.top-chart_dimensions.height/2)+')');
        
     // add points for a start
        chart.selectAll('circle')
            .data(data)
            .enter()
            .append('circle')
                .attr('class',function(d) { return d.type; })
                .attr('id',function(d) { return d.type+'|'+d.experiment+'|'+d[destCol] })
                .attr('cx', function(d) { return x_scale(d[destCol]); })
                .attr('cy', function(d) { return y_scale(d[scoreCol]); })
                .attr('r',3)
                .on('mouseover',function(d) {
                        d3.select(this)
                            .transition()
                            .attr('r',5);
                        show_data(d);
                    })
                .on('mouseout', function(d) {
                        d3.select(this)
                            .transition()
                            .attr('r',3);
                        hide_data();
                    })
                .on('mouseover.tooltip',function(d) {
                        d3.select('text#id'+d[destCol]).remove();
                        chart.append('text')
                            .text(d[prettyName])
                            .attr('x',x_scale(d[destCol])+10)
                            .attr('y',y_scale(d[scoreCol])+5)
                            .attr('id','id'+d[destCol]);
                    })
                .on('mouseout.tooltip',function(d) {
                        d3.select('text#id'+d[destCol])
                            .transition()
                            .duration(500)
                            .style('opacity',0)
                            .remove();
                    })
                .on('click',function(d) { window.open('../'+target+'/'+dest+'?ID='+d[destCol]); });
        
//        // add profiles for genes only
//        if(base=='gene') {
//        	var line = d3.svg.line()
//    	        .x(function(d) {return x_scale(d[destCol])})
//    	        .y(function(d) {return y_scale(d[scoreCol])});
//    	    
//    	    var experiments = d3.scale.ordinal().domain(data.map(function(d) {return d.experiment}));
//    	    
//    	    var exp_data = experiments.domain().map(function(exp) {
//    	            var item = {
//    	                experiment: exp,
//    	                values: data.filter(function(d) { return d.experiment==exp} )
//    	            };
//    	            item.type = item.values[0].type;
//    	            return item;
//    	        }
//    	    );
//    	    
//    	    // add profile plots
//    	    var profiles = chart.selectAll('exp')
//    	        .data(exp_data)
//    	        .enter()
//    	        .append('g')
//    	        .attr('class','line');
//    	    
//    	    profiles.append('path')
//    	         .attr('class',function(d) { return d.type})
//    	         .attr('d',function(d) { return line(d.values) })
//    	         .attr('id',function(d) { return d.experiment })
//    	         .attr('fill',null);
//        }
        
     // define data table
        table = d3.select("#HIPHOPTable").select("table"),
            thead = table.select("thead"),
            tbody = table.select("tbody");
        
        thead.on('click',hide_data); // cheap trick...
        
        var rows = tbody.selectAll("tr")
                        .data(data)
                        .enter()
                        .append("tr")
                            .style('display','none') // keep them hidden for now
                            .attr('id',function(d) { return String(d[destCol]) })
                            .attr('class',function(d) { return d.type })
                            .on('click',function(d) { window.open('../../'+target+'/'+dest+'?ID='+d[destCol]); })
                            .on('mouseover',function() { d3.select(this).style('background-color','lightgrey'); } )
                            .on('mouseout',function() { d3.select(this).style('background-color',null); } );    
        
        var columns = [destCol,prettyName,'concentration','experiment','madl_score','z_score']
        
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
        
        rows.sort(function(a,b) { return d3.ascending(a.type,b.type)});
    }
    
    // extra functions
    function show_data(c) {
    	var id = c[destCol],
        	type = c.type,
        	comp_conc_exp = c.compound_concentration_experiment;
    	hide_data()
    	
        // show header
        thead.style('display','table-header-group');
        
        // show the corresponding table rows...
        tbody.selectAll('tr')
        	.filter(function(d) { return d[destCol]==id && d.type==type
        									// use following code to display only ACTIVE rows 
        									// && 
        									// d.compound_concentration_experiment==comp_conc_exp && 
        									// comp2exp.indexOf(d.compound_concentration_experiment)>-1
        	})
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