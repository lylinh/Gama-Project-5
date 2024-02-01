/**
* Name: city
* Based on the internal empty template. 
* Author: linhntl
* Tags: 
*/


model flu_ex3

/* Insert your model definition here */


global {
	shape_file buildings_shape_file <- shape_file("../includes/building_polygon.shp");	
	shape_file roads_shape_file <- shape_file("../includes/highway_line.shp");

	geometry shape <- envelope(buildings_shape_file);
	graph road_network;
	
	map<road, float> new_weights;
	
	int number_inhabitant <- 100;
	float step <- 5#minute;
	
	// date
	date starting_date <- date([1980,1,2,5,40,0]);
	list<int>  hour_event <- list<int>([4#h,8#h,12#h,16#h,20#h,0#h,2#h,6#h,10#h,14#h,18#h,22#h,
		1#h,3#h,5#h,7#h,9#h,11#h,13#h,15#h,17#h,19#h,21#h,23#h
	]);
	int percent_vacine <- 10 parameter:true;

	init{
		create building from: buildings_shape_file with:(height:10);
		create road from: roads_shape_file;
		road_network <- as_edge_graph(road);
		
		building school <- building sort_by (each.shape.area) at (length(building)-1);
		loop b over: building{
			int r <- rnd(100);
			
			if r <= 50 {
				continue;
			}
			int number_human <- rnd(4,6);
			loop i from: 0 to: number_human { 
			    create inhabitant number: number_human{
					company <- i < 2? any_location_in(school) : any_location_in(one_of(building));
					home <- any_location_in(b);
					location <- home + rnd ({20,20,0});
					bool isInfect  <- flip(0.1);
					if isInfect  {
						is_infected <- true;
					}
				}
			}
		}
		
		 number_inhabitant <- length(inhabitant);

		
	}
	
	reflex timer_count {
		write "update";
		write cycle;
		write current_date;
		write "----------";
		
		int cur <- int(current_date.hour#h + current_date.minute#minute);
		bool event_time <- hour_event contains cur;
		
		if (event_time){
			ask inhabitant {
				if self.is_infected{
					do recover;
				}
			}
				
			list prevacince_inhabitant <- (number_inhabitant * percent_vacine / 100) among inhabitant where (!each.is_vaccined);
				
			loop i over: prevacince_inhabitant {
			    ask i {
			    	self.is_vaccined <- true;	
			    }
			}
		}
	}
	
	
	reflex update_weights when: every(10#s){
		new_weights <- road as_map (each::each.shape.perimeter / each.speed_rate);
	}
}

species inhabitant skills: [moving] { //skills are pre defined
	point target;
	point home;
	point company;
	
	
	// this definition of speed surpersedes the one skill moving 
	float speed <- 1 #km/#h;
	
	// For virus
	bool is_infected <- false;
	bool is_tested <- false;
	float infect_range <- 5.0;
	
	// for character 
	
	int recovery <- 0;
	bool is_vaccined <- false;
	
	reflex move  {
		if is_infected and is_tested{
			target <- home;
		}
		else if (current_date.hour#h + current_date.minute#minute >= 8#h and current_date.hour#h + current_date.minute#minute <= 17#h){
			target <- company;		
		}else{
			target <- home;
		}
		
//		do goto target: target on: road_network move_weights: new_weights; // on :))
		path followed_path <- goto(target: target, on: road_network, move_weights: new_weights, return_path: true);
	}
	
	
	action recover {
		recovery <- recovery + 10;
						
		if recovery >= 100{
			is_infected <- false;
			is_tested <- false;
		}			
	}
	
	reflex infect when: every(5#s){
		ask inhabitant at_distance infect_range{
			if self.is_infected and !myself.is_infected {
				int r <- rnd(100) ;
				if r <= 33 / (myself.is_vaccined ? 3 : 1){
					
					myself.is_infected <- true;
					
				}
			}
		}
	}
	
	
	aspect default {
		draw circle(5) color: (is_infected ) ? #red :#green;
	}
	
	aspect threeD {
		draw pyramid(4) color:  (is_infected) ? #red :#green ;
		draw sphere(2) color:  (is_infected) ? #red :#green at: location + {0,0,3};
	}
}


species building{
	int height;
	bool is_school;
	aspect default{
		draw shape color:is_school?#black: #gray;
	}
	
	aspect threeD{
		draw shape depth: height texture: ["../includes/roof.png","../includes/texture5.jpg"];
	}
}

species road{
	float capacity <- 1 + shape.perimeter / 30#m;
	int nb_driver <- 0 update: length(inhabitant at_distance 0.1);
	float speed_rate <- 1.0 update: exp(-nb_driver/capacity) min: 0.1 ;
	aspect default{
		draw (shape buffer(1 + 3 * (1 - speed_rate))) color: #cyan;
	}
}


experiment flu_explosive type: gui {
	
	float minimum_cycle_duration <- 0.1;
	/** Insert here the definition of the input and output of the model */
	output {
		display map type: 3d {
//			mesh pollution_cell triangulation: true color:#gray transparency: 0.5;
			
			image image_file("../includes/satellite.png") refresh: false;
			
			species building aspect:default refresh: false;
			species road;
			species inhabitant aspect: default;
			
			
		}
	     display "Infected person" {
			chart "Infected person" type: series {
				data "inhabitant infected" value: inhabitant count (each.is_infected=true) color: #red;
				data "inhabitant health" value: inhabitant count (each.is_infected=false) color: #green;
				data "inhabitant vacined" value: inhabitant count (each.is_vaccined) color: #cyan;
			}
    	}
	}
}
























