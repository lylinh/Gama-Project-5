/**
* Name: city
* Based on the internal empty template. 
* Author: linhntl
* Tags: 
*/


model city

/* Insert your model definition here */


global {
	shape_file buildings_shape_file <- shape_file("../includes/building_polygon.shp");	
	shape_file roads_shape_file <- shape_file("../includes/highway_line.shp");

	geometry shape <- envelope(buildings_shape_file);
	graph road_network;
	
	map<road, float> new_weights;

	float step <- 5#minute;
	
	// date
	date starting_date <- date([1980,1,2,7,40,0]);

	int number_inhabitant <- 2000 parameter:true;
	init{
		create building from: buildings_shape_file with:(height:10);
		create road from: roads_shape_file;
		road_network <- as_edge_graph(road);
		
		create inhabitant number: number_inhabitant{
			company <-  any_location_in(one_of(building));
			home <- any_location_in(one_of(building));
			location <- home + rnd ({20,20,0});
			bool infect <- flip(0.1);
			if infect {
				is_infected <- true;
				level <- 1;
			}
		}
		
	}
	
	reflex timer_count {
		
		if ((current_date.hour#h = 4 or current_date.hour#h = 8 or current_date.hour#h = 12 or current_date.hour#h = 16 or current_date.hour#h = 20) and  
			current_date.minute#minute = 0#minute){
			
			ask inhabitant {
				if self.is_infected{
					do recover;
					do virus_upgrade;
				}
			}
			
			write "UPGRADE";
				
			list prevacince_inhabitant <- (number_inhabitant * 5 / 1000) among inhabitant where (!each.is_vaccined);
				
			loop i over: prevacince_inhabitant {
			    ask i {
			    	self.is_vaccined <- true;	
			    }
			}
		}
	}
	
	reflex write_sim_info {
		write cycle;
		write time;  // time = cyle * step
		write current_date;
		write "----------";
	
	}
	
	reflex update_weights when: every(10#s){
		new_weights <- road as_map (each::each.shape.perimeter / each.speed_rate);
	}
}

species inhabitant skills: [moving] { //skills are pre defined
	point target;
	point home;
	point company;
	
	int current_state;
	
	rgb color <- #green;//rnd_color(255);
	
	float pollution_emission <- rnd(90.0, 250.0)/1000;
	
	float proba_leave <- 0.05;
	
	// this definition of speed surpersedes the one skill moving 
	float speed <- 40 #km/#h;
	
	// For virus
	bool is_infected <- false;
	bool is_tested <- false;
	int level <- 0;
	float attack_range <- 5.0;
	
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
	
	
	action infected(int level_virus){
		level <- level_virus;
		attack_range <- 5.0;
		loop times:level{
			attack_range <- attack_range * #pi * rnd(0.5,1.5);
		} 
	}
	
	action virus_upgrade {
		if !is_infected{
			return;
		}
		
		int random <- rnd(1000);
		if random <= 500{
			level <- level + 1;
		}
	}
	
	reflex attack when: every(5#s){
		ask inhabitant at_distance attack_range{
			if self.is_infected and !myself.is_infected {
				int r <- rnd(100) ;
				if r <= 33 / (myself.is_vaccined ? 3 : 1){
					myself.level <- self.level;
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


experiment traffic type: batch repeat: 5 keep_seed: true until: ( time > 10000 ) {
	parameter 'number_inhabitant' var:number_inhabitant among:[1000,2000,5000];
	
	reflex t {
        save [cycle, inhabitant count (each.is_infected=true) ] to: "result.csv" type: "csv";
    }
	
	
	/** Insert here the definition of the input and output of the model */
//	output {
//		display map type: 3d {
////			mesh pollution_cell triangulation: true color:#gray transparency: 0.5;
//			
//			image image_file("../includes/satellite.png") refresh: false;
//			
//			species building aspect:default refresh: false;
//			species road;
//			species inhabitant aspect: default;
//			
//			
//		}
//	    display "Infected person" {
//			chart "Infected person" type: series {
//				data "inhabitant infected" value: inhabitant count (each.is_infected=true) color: #red;
//				data "inhabitant health" value: inhabitant count (each.is_infected=false) color: #green;
//			}
//			
//    	}
//		display "Virus level" {
//			
//			chart "Virus level" type: series {
//				data "Level 1" value: inhabitant count (each.level=1) color: #red;
//				data "Level 2" value: inhabitant count (each.level=2) color: #blue;
//				data "Level 3" value: inhabitant count (each.level>=3) color: #green;
//			}
//    	}
//	}
}
























