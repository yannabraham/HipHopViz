var comp2exp, exp_table , exp_thead, exp_tbody;

function fill(data) {
    "use strict";
    if(data!==null) {
//      show explanation
        d3.select('#ExperimentDesc').style('display','inline')
//          create & fill table
//          define table, thead, tbody
        exp_table = d3.select("#HIPHOPExperiments").select("table"),
            exp_thead = exp_table.select("thead"),
            exp_tbody = exp_table.select("tbody");
        var hidden = null;
        
     // show header
        exp_thead.style('display','table-header-group');
        exp_thead.on('click',toggle_exp);
        
        comp2exp = data.map( function(d) { return d.compound_concentration_experiment_type; } );
        
//          create a row for each object in the data
        var rows = exp_tbody.selectAll("tr")
            .data(data)
            .enter()
            .append("tr")
            	.style('display','table-row') // keep them hidden for now
                .attr('id',function(d) { return d[baseCol] })
                .attr('class',function(d) { return d.type })
                .on('click',function(d) { pop_exp(d.compound_concentration_experiment_type); } )
                .on('mouseover',function() { d3.select(this).style('font-weight','bold'); } )
                .on('mouseout',function() { d3.select(this).style('font-weight',null); } );
          
//        create a cell in each row for each column
        var columns = ['experiment_group','experiment','type','concentration']
        
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
    // Show/Hide table
    function toggle_exp() {
    	if(hidden==null) {
    		exp_tbody.selectAll('tr')
            	.style('display','table-row');
    		hidden = 1;
    	} else {
    		exp_tbody.selectAll('tr')
            	.style('display','none');
    		hidden = null;
    	}
        
    }
    
    // extra functions
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

function pop_exp(val) {
	if(comp2exp.indexOf(val)==-1) {
		comp2exp.push(val)
		exp_tbody.selectAll("tr")
			.filter(function(d) { return d.compound_concentration_experiment_type==val })
				.style('background-color',null);
	} else {
		comp2exp.splice(comp2exp.indexOf(val),1)
		exp_tbody.selectAll("tr")
			.filter(function(d) { return d.compound_concentration_experiment_type==val })
				.style('background-color','lightgrey');
	}
	void_exp()
}

function void_exp() {
	var circles = d3.select('#HIPHOP').selectAll('circle'),
		rows = tbody.selectAll('tr');
	circles.style('fill',null);
	rows.style('background-color',null);
	circles.filter(function(d) { return comp2exp.indexOf(d.compound_concentration_experiment_type)==-1 ;} )
		.style('fill','grey');
	rows.filter(function(d) { return comp2exp.indexOf(d.compound_concentration_experiment_type)==-1 ;} )
		.style('background-color','lightgrey');
}
