   var visutil = {
    isLocatedBottom: function(d) {
            // Before fixing #128: return (d.x>Math.PI/2&&(d.x+d.dx)<Math.PI*5/3);
         var bottom = (d.x>Math.PI/2 && (d.x+d.dx)<5.0);
         // The procedure to decide how to position text (upside down or not) IS very ad hoc. This helps debugging:19
         //if (d.id=="Thursday_parent" || d.id=="SelfEnhancement_parent") {
         //    console.log("isLocatedBottom", d.id, d.x, d.dx, d.x+d.dx, bottom);
         //}
            return bottom;
        },
   
        arc: function(start,end,r0 ) {
            var c0 = Math.cos(start),
                s0 = Math.sin(start),
                c1 = Math.cos(end),
                s1 = Math.sin(end);
            return "M" + r0 * c0 + "," + r0 * s0
              + "A" + r0 + "," + r0 + " 0" + " 0 , 0 " + r0 * c1 + "," + r0 * s1;
        }
     };

    var renderChart = function() {
            if (!this.data) {
         //           console.error("no data found!");
                this.showError();
                return;
            }
            if (this.vis) {
               console.error("Cannot render: Already rendered (this.vis)");
               return;
            }

            var _this = this;
            var dummyData = false;
            var tree = this.data ? (this.data.tree ? this.data.tree : this.data) : null;
            if (!tree || !tree.children || !tree.children.length) {
               /*dummyData = true;
               var dummy = {
               name: "Personality not yet analyzed",
               id: "blank",      
               children: [ { name: "2nd level", id: "2nd level" } ],
               size: 1,
               forceVisible: true
               };
               this.data.children = [ dummy ];
               datautil.adjustSizeInData(dummy, 1.0, "something");*/
               
               console.log("Personality: Data does not contain personality traits", this.data);
               this.switchState(0, "Personality data not yet computed, please wait...");
               
               // Emit an event to ask for the analysis to be run!
               this.emit("data_needed", { userId: this.userId, source: this.source });
               
               return;
            }
            
            //this.initializeSVGandResize(); // In case this method was not yet called. It does nothing if already invoked
            var _widget = this;
            if (!this.loadingDiv) {
                    alert("Widget is not fully initialized, cannot render BarsWidget");
                    return;
            }
            
            this.switchState(1);
            
            // Render legends before doing layout(), so that we get the correct height for that line(s)
            //this.renderLegend();
            // Layout changes the height of the main div to what is left from the other legends/headers/footers
            this._layout();

            
            /// Helper functions
         // Stash the old values for transition.
         function stash(d) {
              d.x0 = d.x;
              d.dx0 = d.dx;
              d.size0=d.size;
              //set the expand flag
              if (d.depth==0 || d.depth==1) {
                 d.expand=1;
              } else {
                 d.expand=0;
              }
         }
         
          // click expand or fold their children
         function expandOrFoldSector(d) {
               if (d.expand!=null && d.depth>1){
                  //ignore root node and first level sectors
               if (d.expand==0){
                  //if the sector is folded
                   // update_anglefactor(d, d.anglefactor+1);
                    // g.data(partition.value(function(a) {                
                     // return a.size; 
                  // }))
                 // .call(sector);
                 if(d.children) d3.select(this).attr("opacity",1);
                   g.filter(function(a) {
                     if (a.parent) 
                     return  a.parent.id==d.id;
                     })
                     .attr("visibility","visible");
                  d.expand=1;
              } else {
                  //if the sector is expanded
                     
                  // update_anglefactor(d, d.anglefactor-1);
                  // g.data(partition.value(function(a) {               
                     // return a.size; 
                  // }))
                 // .call(sector);
                if(d.children) d3.select(this).attr("opacity",1);
                  hideSector(d);
                }
              }
         }

         function hideSector(d){
            g.filter(function(a) {
               if (a.parent) 
                  return  a.parent.id==d.id;
               })
               .attr("visibility","hidden")
               .attr("opacity",1)
               .each(function(a){
                  if (a.children)
                     hideSector(a);
                  });
              d.expand=0;
         }

         
            var sector_right_pad=dummyData ? 0.0001 : 0.04*2 * Math.PI, sector_bottom_pad=5.0;
            //Render a sector with two adjcent arcs in a style of odometor
            function twoArcsRender(radius) {
              // For each small multiple
              function twoArcs(g) {
                g.each(function(d) {
                   g = d3.select(this);
                     g.selectAll("path").remove();
                     g.selectAll("text").remove();
                     
                     var right_pad= d.depth>0 ? sector_right_pad/(3*d.depth): sector_right_pad;
                                 
                  var percentage=d.percentage,
                     percentage2=1;//for percentage sentiment data. it is the percentage of positive+netural
                     
                  //if percentage is null, then give 1
                  if(percentage==null) percentage=1;
                    if(d.percentage_lbl==null) d.percentage_lbl=""; 
                  var label, label_name=d.name, 
                     label_percentage = (d.percentage==null? "": " ("+(d.percentage*100).toFixed(0)+"%)");
                   
                   if (d.depth==1) label=d.name;
                   if (d.depth>1){
                       if (d.id=="sbh_dom"){
                     label=d.name;
                       } else if (d.category=="values") { 
                            label=d.name+" ("+(percentage*100).toFixed(0)+"%)";
                       } else {
                            if(percentage>=1) {
                              percentage=0.99;
                                 console.error("Percentage is over 1!"+d.name);
                              } else if (percentage<=-1) {
                           percentage=-0.99;
                              console.log("Percentage is below -1!"+d.name);
                              }              
                        label=d.name+" ("+(percentage*100).toFixed(0)+"%)";
                           
                           if ((Math.round(parseFloat(percentage)*100)/100)==0) {  
                              label=d.name;
                           }
                              
                       }
                        
                     
                    }  
                    
                    //for request without any result
                    if(d.name=="") {
                     percentage=0; 
                     label="";
                    }


                  //special render perception sector 
                    if (d.perc_neu!=null && ((d.percentage+d.perc_neu)*d.dx<d.dx-sector_right_pad/(3*d.depth))){
                     percentage2=d.percentage+d.perc_neu;
                        
                     d3.svg.arc()
                         .startAngle(function(d) {
                            return d.x +Math.abs(percentage2)*d.dx; 
                      })//x:startangle,
                         .endAngle(function(d) { return d.x + d.dx-sector_right_pad/(3*d.depth); })//dx: endangle,
                         .innerRadius(function(d) { return sector_bottom_pad+d.y; })
                         .outerRadius(function(d) { return d.y + d.dy; });
                     
                     right_pad=0;    
                    }

                     
                    var arc1_extend=(Math.abs(percentage)*d.dx-right_pad)>0? (Math.abs(percentage)*d.dx-right_pad):0;   
                    //Regular renders
                     var arc1 = d3.svg.arc()
                         .startAngle(function(d) { return d.x; })//x:startangle,
                         .endAngle(function(d) { return d.x + arc1_extend; })//dx: endangle,
                         .innerRadius(function(d) { return sector_bottom_pad+d.y; })
                         .outerRadius(function(d) { return d.y + d.dy; });
                               
                  var arc2 = d3.svg.arc()
                          .startAngle(function(d) { return d.x +arc1_extend; })//x:startangle,
                         .endAngle(function(d) { return d.x + Math.abs(percentage2)*d.dx-right_pad; })//dx: endangle,
                         .innerRadius(function(d) { return sector_bottom_pad+d.y; })
                         .outerRadius(function(d) { return d.y + d.dy; });
                         
                   //used for label path
                  
                  var arc_for_label, arc_for_label_number;
                  var arc_label_radius, arc_label_number_radius;
                  if(d.depth==1 && visutil.isLocatedBottom(d)) 
                  {
                     arc_label_radius=d.y + d.dy-(d.y + d.dy-sector_bottom_pad-d.y)/6; 
                     arc_label_number_radius=d.y + d.dy-(d.y + d.dy-sector_bottom_pad-d.y)/8; 
                  }
                  else {
                     arc_label_radius= sector_bottom_pad+d.y+(d.y + d.dy-sector_bottom_pad-d.y)*5/12;
                     arc_label_number_radius=d.y + d.dy-(d.y + d.dy-sector_bottom_pad-d.y)/7;
                  }
                     
                  
                  var bottom = visutil.isLocatedBottom(d);
                  if (bottom) {
                     //special reversed label for bottom data
                        arc_for_label = visutil.arc(d.x + d.dx-right_pad-Math.PI/2, d.x-Math.PI/2, arc_label_radius);
                        arc_for_label_number = visutil.arc(d.x + d.dx-right_pad-Math.PI/2, d.x-Math.PI/2, arc_label_number_radius);
                  } else {
                     
                   arc_for_label = d3.svg.singleArc()
                        .startAngle(function(d) {return d.x; })
                      .endAngle(function(d) { return d.x + d.dx-right_pad; })
                      .radius(function(d) { return d.depth==1? d.y + d.dy-(d.y + d.dy-sector_bottom_pad-d.y)/3: sector_bottom_pad+d.y+(d.y + d.dy-sector_bottom_pad-d.y)*3/5; });
                     
                   arc_for_label_number =  d3.svg.singleArc()
                        .startAngle(function(d) {return d.x; })
                      .endAngle(function(d) { return d.x + d.dx-right_pad; })
                      .radius(function(d) { return d.depth==1? d.y + d.dy-(d.y + d.dy-sector_bottom_pad-d.y)/3: sector_bottom_pad+d.y+(d.y + d.dy-sector_bottom_pad-d.y)/5; });
                    
                    }  
                    
                     d.coloridx=0;
                     
                     if (d.depth==1 || d.depth==0) {
                      d.coloridx=d.id;
                     } else {
                      d.coloridx=d.parent.coloridx;
                     }
                     
                     var arc1color;
                  if (d.coloridx=="personality") arc1color=_widget.COLOR_PALLETTE[0];        
                  if (d.coloridx=="needs") arc1color=_widget.COLOR_PALLETTE[1];
                  if (d.coloridx=="values") arc1color=_widget.COLOR_PALLETTE[2];
                  if (d.coloridx=="sr") arc1color=_widget.COLOR_PALLETTE[3];
                  if (d.coloridx=="sbh") arc1color=_widget.COLOR_PALLETTE[4];
                  if (d.coloridx=="blank") arc1color=_widget.COLOR_PALLETTE[6];
                  //console.log(d.coloridx, arc1color, d.depth);
                         
                     arc1color=d.depth<2 ? arc1color : d3.rgb(arc1color).brighter(Math.pow(1.1,d.depth*1.5));
                     
                       var strokecolor= d3.rgb(arc1color).darker(0.8);
                     
                       
                   if(!d.children && d.id!="srasrt"&& d.id!="srclo" && d.id!="srdom" ){
                     //&& d.type!="value"
                     //leaf nodes
                       var label=d.name;
                       var bar_length_factor=10/(d.depth-2);
                     
                       var percentage=d.percentage;   
                     
                     
                     //different bar_length factors
                      if (d.parent)    
                      if (d.parent.parent) {
                        
                           if (d.parent.parent.id=="needs"||d.parent.parent.id=="values") { 
                              bar_length_factor=1;
                        }

                           if (d.parent.parent.id=="sbh")   {
                              //alert(d.name);
                              bar_length_factor=0;
                              if (percentage>1) { 
                                 percentage=Math.random();
                                 d.percentage=percentage;
                              }
                           }
                          if (d.parent.parent.parent) 
                           if (d.parent.parent.parent.id=="personality") bar_length_factor=1;
                           
                       } else {
                        console.log(d.name+": Parent is null!");
                       }
                      
                   
                     
                     var     inner_r=sector_bottom_pad+d.y,
                           out_r;
                           
                              
                        out_r=sector_bottom_pad+d.y+bar_length_factor*Math.abs(percentage)*d.dy;
                     
                     if (d.percentage_lbl=="Low") out_r=sector_bottom_pad+d.y+bar_length_factor*0.2*d.dy;
                     
                     
                     var _bar = d3.svg.arc()
                               .startAngle(d.x)
                               .endAngle(d.x + d.dx)
                               .innerRadius(inner_r)
                               .outerRadius(out_r); // Draw leaf arcs
                  
                     
                      g.append("path")
                            .attr("class", "_bar")
                            .attr("d", _bar)
                            .style("stroke", "#EEE")
                            .style("fill", function (d) {
                                 return d3.rgb(arc1color).darker(0.5);
                            }); 
                        
                        
                        
                         //add label;
                         
                        var rotate=0,
                        lbl_anchor="start",
                        dy_init=0,
                        label=d.name;
                     
                     if (d.x>Math.PI) {
                           rotate=d.x*180/Math.PI+90;
                           lbl_anchor="end";
                           dy_init=-d.dx*20*Math.PI;
                  } else {
                        rotate=d.x*180/Math.PI-90;
                        lbl_anchor="start";
                           dy_init=5+d.dx*20*Math.PI;
                  }
                        
                     var max_label_size=13, lable_size=10;
                     
                     if ((7.5+15*Math.PI*d.dx)>max_label_size) {
                        lable_size=max_label_size;
                     }        
                        
                       label=label+" ("+(percentage*100).toFixed(0)+"%)";

                            
                       g.append("text")
                           .attr("dy", dy_init)
                           .attr("class","sector_leaf_text")
                           //.attr("fill",d3.rgb(arc1color).darker(Math.pow(1.1,d.depth*2)))
                           .attr("font-size", lable_size)
                           .attr("text-anchor", lbl_anchor)
                           .attr("transform", "translate("+(out_r+5)*Math.sin(d.x)+","+(-(out_r+5)*Math.cos(d.x))+") "+"rotate("+rotate+")") 
                           .text(label);
                     
                    } else {   
                     //non-bar/non-leaf sector        
                        g.append("path")
                            .attr("class", "arc1")
                            .attr("d", arc1)
                            .style("stroke", strokecolor) // was: arc1color
                            .style("fill", arc1color );
                           
                               
                         g.append("path")
                            .attr("class", "arc2")
                            .attr("d",arc2)
                            .style("stroke", strokecolor) // was: arc1color
                             .style("fill", arc1color )
                             .style("fill-opacity", 0.15 );
                         
                        //draw label:
                        //path used for label   
                         g.append("path")
                            .attr("class", "arc_for_label")
                            // NOTE HB: adding widget.id so we to avoid name clashing                           
                            .attr("id",function(d) { return _this.id+"_"+d.id+".arc_for_label"; })
                             .attr("d", arc_for_label)
                            .style("stroke-opacity", 0)
                            .style("fill-opacity", 0 );
                            
                         
                           //add label 
                          g.append("text")
                           .attr("class","sector_label")
                            .attr("visibility", function(d) { return d.depth==1 ? "visible" : null; })
                            //.attr("font-family","sans-serif")
                            .attr("class","sector_nonleaf_text")
                            //.attr("fill", d3.rgb(arc1color).darker(2))
                            .append("textPath")
                              .attr("class","sector_label_path")
                              .attr("position-in-sector", d.depth<=1 ? "center" : (bottom ? "inner" : "outer")) // Since both text lines share the same "d", this class annotation tells where is the text, helping to determine the real arc length
                              .attr("font-size", function(d) { return 30/Math.sqrt(d.depth+1); })
                              // NOTE HB: Why do we need this xlink:href? In any case, adding widget.id so we to avoid name clashing                            
                             .attr("xlink:href", function(d) { return "#"+_this.id+"_"+d.id+".arc_for_label"; })
                             .text(label_name);
                          
                          //draw label number
                          //path used for label number 
                          if (d.depth>1){
                            g.append("path")
                                  .attr("class", "arc_for_label_number")
                                  // NOTE HB: adding widget.id so we to avoid name clashing                           
                                  .attr("id",function(d) { return _this.id+"_"+d.id+".arc_for_label_number"; })
                                   .attr("d", arc_for_label_number)
                                  .style("stroke-opacity", 0)
                                  .style("fill-opacity", 0 );
                                  
                               
                                 //add label 
                                g.append("text")
                                 .attr("class","sector_label_number ")
                                  .attr("visibility", function(d) { return d.depth==1 ? "visible" : null; })
                                  //.attr("font-family","sans-serif")
                                  .attr("class","sector_nonleaf_text")
                                  //.attr("fill", d3.rgb(arc1color).darker(2))
                                  .append("textPath")
                                    .attr("class","sector_label_number_path")
                                 .attr("position-in-sector", bottom ? "outer" : "inner") // Since both text lines share the same "d", this class annotation tells where is the text, helping to determine the real arc length
                                    .attr("font-size", function(d) { return 10; })
                                    // NOTE HB: Why do we need this xlink:href? In any case, adding widget.id so we to avoid name clashing                            
                                   .attr("xlink:href", function(d) { return "#"+_this.id+"_"+d.id+".arc_for_label_number"; })
                                   .text(label_percentage);
                          }
                         
                     
                     }  
                });

              }

              return twoArcs;
            };
            
            function updateLabelLayout() {
               updateLabelLayoutWithClass('.sector_label_path');
               updateLabelLayoutWithClass('.sector_label_number_path');
            }
            
            function updateLabelLayoutWithClass(_class) {
               var max_font_size_base=16;
               var min_font_size_base=9;
               var margin=10;
               _this.d3vis.selectAll(_class).each(function(d){
                  var d3this = d3.select(this);
               var curNd = d3this.node();
               var text = d3this.text();
               if(text && text.length>0) {
                  var position = d3.select(this).attr('position-in-sector'); // 'inner' or 'outer'
                  var frac = position=='center' ? 0.5 : position=='outer' ? 2/3 : 1/3;
                  var sector_length=(d.y+d.dy*frac)*d.dx;
                  var text_length=curNd.getComputedTextLength(); //+margin;
                  var cur_font_size=d3.select(this).attr("font-size");
                  var new_font_size=cur_font_size*sector_length/text_length;
                  var new_text_length = text_length * new_font_size/cur_font_size;
                     //if (d.id=="Openness_parent" || d.id=="personality") {
                     if (d.depth==1) {
                        console.log("updateLabelLayout ["+d.id+"] '"+text+"', |text|", text_length, "|sec|=", sector_length, "cur_size", cur_font_size, "new_size", new_font_size, "new_text_legth", new_text_length,d, curNd, position);
                     //}else{
                     // console.log("updateLabelLayout ["+d.id+"] '"+text+"'");
                     }
                  if(new_font_size>max_font_size_base/(0.4*d.depth+0.6)) {                   
                     new_font_size=max_font_size_base/(0.4*d.depth+0.6);
                     if (d.depth==1)
                        console.log("fixed to", new_font_size);            
                  }
                  
                  d3.select(this).attr("font-size",new_font_size);
                  //set new offset:
                  d3.select(this).attr("startOffset", (sector_length-curNd.getComputedTextLength())/2);
//                d3.select(this).attr("startOffset",0); //(sector_length-curNd.getComputedTextLength())/2);
               }
            });
            };

         function adjustSectorWidth(d) {
            //alert(d.name);
            if (!d.anglefactor) d.anglefactor=1;
            if (d3.event.sourceEvent.type == 'DOMMouseScroll' && d3.event.sourceEvent.ctrlKey) {
               //ctrl+mousewheel to adjust sector width           
               if (d3.event.sourceEvent.detail <0) {
                  //Increase angle
                  d.anglefactor+=angle_factor_increment;
               } else {
                  //Decrease angle
                  d.anglefactor=(d.anglefactor-angle_factor_increment)> angle_factor_min ? d.anglefactor-angle_factor_increment: angle_factor_min;
               }
               
               update_anglefactor(d, d.anglefactor);
               g.data(partition.value(function(a) {               
                  return a.size; 
               }))
                 .call(sector);
               updateLabelLayout();             
            }
         };
            
         var width = this.dimW, height = this.dimH;
         // The flower had a radius of 640 / 1.9 = 336.84 in the original.
         var radius = Math.min(width, height) / 3.2;
         var sector = twoArcsRender(radius);

         var vis = this.d3vis.append("g")
            .attr("transform", "translate(" + (width / 2)+ "," + height / 2 + ")") //center the graph of "g"
            .append("g")
//$            .call(d3.behavior.drag().on("drag", dojo.hitch(this, this._dragpanevent)))
//$            .call(d3.behavior.zoom().on("zoom", dojo.hitch(this, this._zoomevent))).on("dblclick.zoom", null);
         this.vis = vis; // HACK! Keeping a reference both to d3vis and vis (svg and g objects) 
         
         var partition = d3.layout.partition()
             .sort(null)
             .size([2 * Math.PI, radius])
             .value(function(d) { return d.size; });

         var profile = tree;
         
         var g = vis.data([profile]).selectAll("g")
             .data(partition.nodes)
             .enter().append("g")
             .attr("class", "sector")
             .attr("visibility", function(d) { return d.depth==2 || d.forceVisible ? "visible" : "hidden"; }) // hide non-first level rings
             .call(sector)
             .each(stash)
             .on("click", expandOrFoldSector)
             .on("mouseover", function(d) {
               _this.showTooltip(d, this);
             })
             .on("mouseout", function(d) {
               _this.showTooltip();
             })
             .call(d3.behavior.zoom().on("zoom", adjustSectorWidth))
             ;
         
         // Shift the text pieces clockwise (to somewhat center them).
         updateLabelLayout();
//$         this._addPersonImage(this.user.largeImgUrl || this.user.pictureURL || this.DEFAULT_PERSON_IMAGE, dummyData); //'http://a0.twimg.com/profile_images/1352867286/jeff.jpg');
        };
