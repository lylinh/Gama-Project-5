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
	
	float step <- 2 #s;
	
	int number_population <- 200;
	
	int current_min<- 0;
	int current_hour<- 0;
	int current_day<- 0;
	list<inhabitant> character;
	
	int inhabitant_infected <- 0;
	
	/** Insert the global definitions, variables and actions here */
	init{
		create building from: buildings_shape_file with:(height:10);
		create road from: roads_shape_file;
		road_network <- as_edge_graph(road);
//		point local <- any_location_in(one_of(building));
//		point local <- {1762.842545783989,1479.1367305844662,0.0};
		point dummy_target <- {2065.809003953516,1106.092212182626,0.0};
		
		write "building count: " + length(building);
		building school <- building sort_by (each.shape.area) at (length(building)-1);
		school.is_school <- true;
		int count <- 0;
//		loop b over: building{
//			int r <- rnd(100);
//			
//			if r <= 75 {
//				continue;
//			}
//			int number_human <- 2;//rnd(4,6);
//			count <- count + 1;
//			loop i from: 0 to: number_human { 
//			    create inhabitant number: number_population{
//		//			target <- dummy_target;
//					company <- i < 2? any_location_in(school) : any_location_in(one_of(building));
//					home <- any_location_in(b);
//					location <- home + rnd ({20,20,0});
//					bool infect <- flip(0.1);
//					if infect {
//						is_infected <- true;
//						level <- 1;
//					}
//				}
//			}
//		}
		create inhabitant number: 2000{
		//			target <- dummy_target;
			company <-  any_location_in(one_of(building));
			home <- any_location_in(one_of(building));
			location <- home + rnd ({20,20,0});
			bool infect <- flip(0.1);
			if infect {
				is_infected <- true;
				level <- 1;
			}
		}
		
		write 'number home:' +count;
//		create inhabitant number: 10{
//			home <- dummy_target;
//			company <- dummy_target;
//			location <- dummy_target + rnd ({20,20,0});
//			color <- #blue;
//			target <- nil;
//		}
	}
	
	reflex countdown when: every(1#s){
		current_min <- current_min + 5;
			
		if current_min >= 60{
			current_min <- 0;
			current_hour <- current_hour + 1;
			
			
			if current_hour = 8{
				ask inhabitant {
					self.target <- (self.is_tested? self.home : self.company) + rnd ({20,20,0});
				}
			}
				
				
			if current_hour = 18{
				ask inhabitant {
					self.target <- self.home+ rnd ({20,20,0});
				}
			}
			
			
			if current_hour >= 24{
				current_hour <- 0;
				current_day <- current_day + 1;
				
				ask inhabitant {
					if self.is_infected{
						do recover;
					}
					
					do virus_upgrade;
				}
				
				list pretest_inhabitant <- (number_population * 2 / 100) among inhabitant where (each.is_tested);
				
				loop i over: pretest_inhabitant {
				    ask i {
				    	self.is_tested <- true;	
				    }
				}
				
				list prevacince_inhabitant <- (number_population * 5 / 1000) among inhabitant where (!each.is_vaccined);
				
				loop i over: prevacince_inhabitant {
				    ask i {
				    	self.is_vaccined <- true;	
				    }
				}
			}
		}
	}
	
	
	reflex update_weights when: every(10#s){
		new_weights <- road as_map (each::each.shape.perimeter / each.speed_rate);
	}
	reflex diff{
		diffuse var: grid_value on: pollution_cell;
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
	
//	reflex choose_target when: target = nil and flip(proba_leave) {
//		target <- any_location_in(one_of(building));
//	}
	
//	reflex recover when:every(1#s){
//		if is_infected{
//			recovery <- recovery + 10;
//			write "recovery: " + recovery;
//			if recovery >= 100{
//				is_infected <- false;
//				recovery <- 0;
//			}
//		}
//	}
//	
	
	reflex move when: target != nil {
//		do goto target: target on: road_network move_weights: new_weights; // on :))
		path followed_path <- goto(target: target, on: road_network, move_weights: new_weights, return_path: true);
		
		if is_infected and is_tested{
			target <- home;
		}
//		else if location = company {
//			target <- home;
//		}else if location = home {
//			target <- company;
//		}
	}
	
	action virus_upgrade {
		if !is_infected{
			return;
		}
		
		
		int random <- rnd(1000);
		if random <= 5{
			level <- level + 1;
		}
	}
	
	action recover {
		recovery <- recovery + 50;
						
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
	
	reflex attack when: !empty(inhabitant at_distance attack_range ) every(10#s){
		ask inhabitant at_distance attack_range{
			if self.is_infected  and !myself.is_infected {
				int r <- round(rnd(100) / (myself.is_vaccined ? 3 : 1));
				if r <= 33 {
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

grid pollution_cell height:50 width:50 neighbors: 8{
//	float grid_value <- rnd(10.0);
	reflex disappears when: every(1#h){
		grid_value <- grid_value * 0.9;
	}

}



experiment traffic type: gui {
	
	float minimum_cycle_duration <- 0.1;
	/** Insert here the definition of the input and output of the model */
	output {
		display map type: 3d {
			mesh pollution_cell triangulation: true color:#gray transparency: 0.5;
			
			image image_file("../includes/satellite.png") refresh: false;
			
			species building aspect:default refresh: false;
			species road;
			species inhabitant aspect: default;
			
			graphics timer{
				draw ""+current_day + "Days " + current_hour + ":" + current_min 
					font:font("Helveica", 48, #plain) at: {world.shape.width/2,world.shape.height,0} color:#black;
			}
			
		}
	    display "my_display" {
			chart "my_chart" type: series {
				data "inhabitant_infected" value: inhabitant count (each.is_infected=true) color: #red;
			}
    	}
		
	}
}
























