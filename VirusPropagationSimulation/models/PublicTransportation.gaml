/***
* Name: PublicTransportation
* Author: Origami
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model PublicTransportation
import "../models/Propagation_simulation_model.gaml"

species public_transportation skills:[moving] parallel:true{
		point destiny;
		float avgSpd<-50#m/#s;
		int minutes_waiting<-0;
		list<bus_stop> stops;
		point next_stop;
		point actual_stop;
		image_file icon<-image_file("../V2images/guagua.png");
		
		reflex change_target when: !empty(stops) and minutes_waiting=30{
			remove from:stops index:0;
			minutes_waiting<-0;
			if(!empty(stops)){
				next_stop <- stops[0].get_street_point();
			}
			else{
				next_stop<- (border closest_to(self)).get_street_point();
				destiny <-next_stop;
			}	
		}
		reflex wait_in_stop when: location= next_stop.location{
			ask (SEIR_people at_distance(8)){
					if(moving and !in_bus){
					do check_bus(myself);
					}
				} 
				minutes_waiting<-minutes_waiting+1 ;
		}
		reflex go_out when: location = destiny{
			do die;
		}
		reflex move{
			speed<-avgSpd;
			do goto target: next_stop on:cell where(each.is_street);
		}

		
		aspect base{
			draw icon size:18 color:rgb (36, 200, 200,255);
		}

		
}
		
species bus_stop{
	action get_street_point{
		return (cell where(each.is_street) closest_to(self)).location;
	}
	aspect base{
		draw circle(20) color:#blue;	
	}	
}
species border{
	action get_street_point{
		return (cell where(each.is_street) closest_to(self)).location;
	}
	aspect base{
		draw circle(20) color:#blue;	
	}	
}
/* Insert your model definition here */

