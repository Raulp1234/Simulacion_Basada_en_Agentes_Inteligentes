/***
* Name: PeopleSpecies
* Author: Origami
* Descriptito: 
* Tags: Tag1, Tag2, TagN
***/

model PeopleSpecies

//import "../models/Propagation_simulation_model.gaml"
import "../models/Activities.gaml"
import "../models/PublicTransportation.gaml"
species People skills:[moving] parallel:true{
	float avgSpd<-20#m/#s;
	building home;
	building workplace;
	building sch;
	bool works;
	point the_target <- nil ;
	cell myCell update:cell at(self.location);
	string place;
	bool inside_building<-true;
	point street_target_origin<-nil;
	point street_target_destiny<-nil;
	building current_building;
	bool moving<-false;
	list<activity> schedule;
	int age;
	string sex;
	string age_group;
	bool in_bus;
	public_transportation my_bus;
	bus_stop my_stop;
	//////////////MOVING/////////////////
	reflex move when: the_target != nil and !in_bus{
		moving<-true;
		if inside_building and street_target_origin !=nil{
			do move_out_building;
		}
		else if street_target_destiny = nil and not inside_building {
			do move_in_building;
		}
		else if street_target_destiny!=nil {
			speed<-avgSpd;
			do goto target:street_target_destiny on:cell where(each.is_street);
			/*path path_followed <- goto(target:the_target, to:the_graph, return_path: true);
			list<geometry> segments <- path_followed.segments;
			loop line over: segments {
				float dist <- line.perimeter;
			}*/
			if street_target_destiny = location {
				street_target_destiny <- nil ;
			}
		}
	}
	action move_out_building{
		if street_target_origin = location{
			street_target_origin <- nil ;
			inside_building<-false;
			current_building<-nil;
		}
		else{
			speed<-avgSpd;
			do goto target:street_target_origin;
		}
	}
	action move_in_building{
		if location = the_target{
			current_building <- schedule[0].target_building;
			moving<-false;
			inside_building<-true;
			the_target<-nil;
		}
		else{
		speed<-avgSpd;
		do goto target:the_target;
		}
	}
	action define_street_moving_targets{
		street_target_origin <-((cell where (each.is_street)) closest_to self).location;
		street_target_destiny <-((cell where (each.is_street)) closest_to the_target).location;
	}
	
	//////////////////////BUS RELATED///////////////////////
	
	action check_bus(public_transportation bus){
		list<bus_stop> stops <-bus.stops;
		loop st over:stops{
			if(((st.location) distance_to(self.the_target)) < ((self.location) distance_to(the_target))){
				my_stop<-st;
			}
		}
		if(my_stop != nil){
			do get_in_bus bus:bus;
		}
	}
	action get_in_bus(public_transportation bus){
		in_bus <- true;
		my_bus<-bus;
		location<-any_location_in(my_bus);
	}
	reflex move_with_bus when: in_bus{
		location<- my_bus.location;
	}
	reflex get_off_bus when: in_bus and location=my_stop.get_street_point(){
		location <-my_stop.get_street_point();
		in_bus <-false;		
		my_bus<-nil;
		my_stop<-nil;
	}
	
	
	//////////////////WANDERING/////////////
	
	reflex wander when:current_building!=nil and every (20# cycles) and not moving{
		do goto target:any_location_in(current_building);
	}
	
	////////////////////ACTIVITY RELATED///////////////
	action check_schedule{
		if length(schedule)>1{
			activity next_activity <- schedule[1];
			if simulation_date.hour=(next_activity.start_hour){
				if(current_building!=next_activity.target_building){
				the_target<-any_location_in(next_activity.target_building);
				do define_street_moving_targets;
				}
				activity old_activity<-schedule[0];
				remove from:schedule index:0;
				ask old_activity{
					do die;
				}
			}
		}
	}
	action create_schedule{
		schedule<-[];
		activity new_activity;
		create activity{
			new_activity<-self;
		}
		activity new_activity2;
		create activity{
			new_activity2<-self;
		}
		activity new_activity3;
		create activity{
			new_activity3<-self;
		}
		activity new_activity4;
		create activity{
			new_activity4<-self;
		}
			switch age_group{
				match "kid"{
					/////////Staying Home///////////
					new_activity.start_hour<-1;
					new_activity.end_hour<-7;
					new_activity.target_building<- home;
					new_activity.name<-"Staying home";
					add item:copy(new_activity) to:schedule;
					//////////Go to school//////////////
					new_activity2.start_hour<-7+rnd(1);
					new_activity2.end_hour<-16;
					new_activity2.target_building<- sch;
					new_activity2.name<- "Studying";
					add item:(copy(new_activity2)) to:schedule;
					////////////////Go to park or stay home//////////////////
					new_activity3.start_hour<-new_activity2.end_hour;
					new_activity3.end_hour<-19+rnd(2);
					new_activity3.target_building<-flip(0.5)? home:one_of(recreations where (each.type="park"));
					new_activity3.name<-new_activity3.target_building=home?"Staying home":"Recreating";
					add item:copy(new_activity3) to:schedule;
					///////////////////go to home if not in/////////////////////
					if new_activity3.target_building!=home{
					new_activity4.start_hour<-new_activity3.end_hour;
					new_activity4.end_hour<-1;
					new_activity4.target_building<- home;
					new_activity4.name<-"Staying home";
					add copy(new_activity4) to:schedule;
					}
				}
				match "teen"{		
					/////////////////stay home////////////////
					new_activity.start_hour<-1;
					new_activity.end_hour<-7;
					new_activity.target_building<- home;
					new_activity.name<-"Staying home";
					add copy(new_activity) to:schedule;
					////////////////////go to school//////////////
					new_activity2.start_hour<-7+rnd(1);
					new_activity2.end_hour<-16;
					new_activity2.target_building<- sch;
					new_activity2.name<- "Studying";
					add copy(new_activity2) to:schedule;
					//////////////////////////////go to recreation. stay home or visit friend/////////////
					new_activity3.start_hour<-16;
					new_activity3.end_hour<-19+rnd(3);
					new_activity3.target_building<- flip(0.3)? home:(flip(0.5)? one_of(recreations):one_of(houses));
					new_activity3.name<-new_activity3.target_building=home?"Staying home":(new_activity3.target_building.is_recreation?"Recreating":"Visiting other house");
					add copy(new_activity3) to:schedule;
					//////////////////go to home if not///////////////////
					if new_activity3.target_building!=home{
					new_activity4.start_hour<-new_activity3.end_hour;
					new_activity4.end_hour<-1;
					new_activity4.target_building<- home;
					new_activity4.name<-"Staying home";
					add copy(new_activity4) to:schedule;
					}
				}
				match "young"{
					/////////////stay home/////////////
					new_activity.start_hour<-1;
					new_activity.end_hour<-6;
					new_activity.target_building<- home;
					new_activity.name<-"Staying home";
					add copy(new_activity) to:schedule;
					//////////////go to work || wander////////
					new_activity2.start_hour<-6+rnd(4);
					new_activity2.end_hour<-12+rnd(6);
					new_activity2.target_building<- flip(0.6)?workplace:one_of(building);
					new_activity2.name<- new_activity2.target_building=home?"Staying home":"Working";
					add copy(new_activity2) to:schedule;
					////////////////////////stay home || visit friend || go to recreation///////////////
					new_activity3.start_hour<-new_activity2.end_hour;
					new_activity3.end_hour<-19+rnd(3);
					new_activity3.target_building<- flip(0.5)? home:(flip(0.5)? one_of(recreations):one_of(houses));
					new_activity3.name<-new_activity3.target_building=home?"Staying home":(new_activity3.target_building.is_recreation?"Recreating":"Visiting other house");
					add copy(new_activity3) to:schedule;
					//////////////////go home if not//////////////
					if new_activity3.target_building!=home{
					new_activity4.start_hour<-new_activity3.end_hour;
					new_activity4.end_hour<-1;
					new_activity4.target_building<- home;
					new_activity4.name<-"Staying home";
					add copy(new_activity4) to:schedule;
					}
				}
				match "adult"{
					/////////////////stay home//////////////
					new_activity.start_hour<-1;
					new_activity.end_hour<-7;
					new_activity.target_building<- home;
					new_activity.name<-"Staying home";
					add  copy(new_activity) to:schedule;
					/////////go to work////////////////////////
					new_activity2.start_hour<-6+rnd(4);
					new_activity2.end_hour<-12+rnd(6);
					new_activity2.target_building<- workplace;
					new_activity2.name<-"Working";
					add copy(new_activity2) to:schedule;
					///////////////////stay home // visit house///////////
					new_activity3.start_hour<-new_activity2.end_hour;
					new_activity3.end_hour<-19+rnd(3);
					new_activity3.target_building<- flip(0.7)? home:one_of(houses);
					new_activity3.name<-new_activity3.target_building=home?"Staying home":"Visiting other house";
					add copy(new_activity3) to:schedule;
					/////////////go home if not////////////
					if new_activity3.target_building!=home{
					new_activity4.start_hour<-new_activity3.end_hour;
					new_activity4.end_hour<-1;
					new_activity4.target_building<- home;
					new_activity4.name<-"Staying home";
					add copy(new_activity4) to:schedule;
					}
				}
				
				match "old"{
					////////////////////////stay home//////////////
					new_activity.start_hour<-1;
					new_activity.end_hour<-6;
					new_activity.target_building<- home;
					new_activity.name<-"Staying home";
					add  copy(new_activity) to:schedule;
					///////////////////go to work if works || go to market////////////////
					new_activity2.start_hour<-6+rnd(4);
					new_activity2.target_building<- works?workplace:one_of(markets);
					new_activity2.end_hour<-works?12+rnd(6):(new_activity2.start_hour+rnd(2)+1);
					new_activity2.name<-works?"Working":"Shoping";
					add copy(new_activity2) to:schedule;
					///////////////////stay home // visit house///////////
					new_activity3.start_hour<-new_activity2.end_hour;
					new_activity3.end_hour<-19+rnd(3);
					new_activity3.target_building<- flip(0.7)? home:one_of(houses);
					new_activity3.name<-new_activity3.target_building=home?"Staying home":"Visiting other house";
					add copy(new_activity3) to:schedule;
					/////////////go home if not////////////
					if new_activity3.target_building!=home{
					new_activity4.start_hour<-new_activity3.end_hour;
					new_activity4.end_hour<-1;
					new_activity4.target_building<- home;
					new_activity4.name<-"Staying home";
					add copy(new_activity4) to:schedule;
				}
			}	
	
	}
	
	}
	action create_weekend_schedule{
		schedule<-[];
		activity new_activity;
		create activity{
			new_activity<-self;
		}
		activity new_activity2;
		create activity{
			new_activity2<-self;
		}
		activity new_activity3;
		create activity{
			new_activity3<-self;
		}
		activity new_activity4;
		create activity{
			new_activity4<-self;
		}
		switch age_group{
				match "kid"{
					////////////////stay home/////////
					new_activity.start_hour<-1;
					new_activity.end_hour<-6;
					new_activity.target_building<- home;
					new_activity.name<-"Staying home";
					add copy(new_activity) to:schedule;
					////////////////Go to park or stay home//////////////////
					new_activity2.start_hour<-8;
					new_activity2.end_hour<-11+rnd(1);
					new_activity2.target_building<-flip(0.5)? home:one_of(recreations where (each.type="park"));
					new_activity2.name<-new_activity2.target_building=home?"Staying home":"Recreating";
					add item:copy(new_activity2) to:schedule;
					////////////////go home if not (lunch)////////
					if new_activity.target_building!=home{
					new_activity3.start_hour<-new_activity2.end_hour;
					new_activity3.end_hour<-1;
					new_activity3.target_building<- home;
					new_activity3.name<-"Staying home";
					add copy(new_activity3) to:schedule;
					}
				}
				match "teen"{
					/////////////stay home/////////////
					new_activity.start_hour<-1;
					new_activity.end_hour<-6;
					new_activity.target_building<- home;
					new_activity.name<-"Staying home";
					add copy(new_activity) to:schedule;
					//////////////wander || stay home////////
					new_activity2.start_hour<-6+rnd(4);
					new_activity2.end_hour<-12+rnd(6);
					new_activity2.target_building<- flip(0.5)?home:one_of(building where(not each.is_work));
					new_activity2.name<- new_activity2.target_building=home?"Staying home":"Wandering";
					add copy(new_activity2) to:schedule;
					////////////////////////stay home || visit friend || go to recreation///////////////
					new_activity3.start_hour<-new_activity2.end_hour;
					new_activity3.end_hour<-19+rnd(3);
					new_activity3.target_building<- flip(0.5)? home:(flip(0.5)? one_of(recreations):one_of(houses));
					new_activity3.name<-new_activity3.target_building=home?"Staying home":(new_activity3.target_building.is_recreation?"Recreating":"Visiting other house");
					add copy(new_activity3) to:schedule;
					//////////////////go home if not//////////////
					if new_activity3.target_building!=home{
					new_activity4.start_hour<-new_activity3.end_hour;
					new_activity4.end_hour<-1;
					new_activity4.target_building<- home;
					new_activity4.name<-"Staying home";
					add copy(new_activity4) to:schedule;
					}
				}
				match "young"{
					/////////////stay home/////////////
					new_activity.start_hour<-1;
					new_activity.end_hour<-6;
					new_activity.target_building<- home;
					new_activity.name<-"Staying home";
					add copy(new_activity) to:schedule;
					//////////////wander || stay home////////
					new_activity2.start_hour<-6+rnd(4);
					new_activity2.end_hour<-12+rnd(6);
					new_activity2.target_building<- flip(0.5)?home:one_of(workabable);
					new_activity2.name<- new_activity2.target_building=home?"Staying home":"Wandering";
					add copy(new_activity2) to:schedule;
					////////////////////////stay home || visit friend || go to recreation///////////////
					new_activity3.start_hour<-new_activity2.end_hour;
					new_activity3.end_hour<-19+rnd(3);
					new_activity3.target_building<- flip(0.5)? home:(flip(0.5)? one_of(recreations):one_of(houses));
					new_activity3.name<-new_activity3.target_building=home?"Staying home":(new_activity3.target_building.is_recreation?"Recreating":"Visiting other house");
					add copy(new_activity3) to:schedule;
					//////////////////go home if not//////////////
					if new_activity3.target_building!=home{
					new_activity4.start_hour<-new_activity3.end_hour;
					new_activity4.end_hour<-1;
					new_activity4.target_building<- home;
					new_activity4.name<-"Staying home";
					add copy(new_activity4) to:schedule;
					}
				}
				match "adult"{
					////////////////////////stay home//////////////
					new_activity.start_hour<-1;
					new_activity.end_hour<-7;
					new_activity.target_building<- home;
					new_activity.name<-"Staying home";
					add  copy(new_activity) to:schedule;
					///////////////////go to work if works || go to market////////////////
					new_activity2.start_hour<-6+rnd(4);
					new_activity2.target_building<- one_of(markets);
					new_activity2.end_hour<-new_activity2.start_hour+rnd(2)+1;
					new_activity2.name<-"Shoping";
					add copy(new_activity2) to:schedule;
					///////////////////stay home // visit house///////////
					new_activity3.start_hour<-new_activity2.end_hour;
					new_activity3.end_hour<-19+rnd(3);
					new_activity3.target_building<- flip(0.7)? home:one_of(houses);
					new_activity3.name<-new_activity3.target_building=home?"Staying home":"Visiting other house";
					add copy(new_activity3) to:schedule;
					/////////////go home if not////////////
					if new_activity3.target_building!=home{
					new_activity4.start_hour<-new_activity3.end_hour;
					new_activity4.end_hour<-1;
					new_activity4.target_building<- home;
					new_activity4.name<-"Staying home";
					add copy(new_activity4) to:schedule;
				}

				}
				match "old"{
					////////////////////////stay home//////////////
					new_activity.start_hour<-1;
					new_activity.end_hour<-7;
					new_activity.target_building<- home;
					new_activity.name<-"Staying home";
					add  copy(new_activity) to:schedule;
					///////////////////go to work if works || go to market////////////////
					new_activity2.start_hour<-6+rnd(4);
					new_activity2.target_building<- one_of(markets);
					new_activity2.end_hour<-new_activity2.start_hour+rnd(2)+1;
					new_activity2.name<-"Shoping";
					add copy(new_activity2) to:schedule;
					///////////////////stay home // visit house///////////
					new_activity3.start_hour<-new_activity2.end_hour;
					new_activity3.end_hour<-19+rnd(3);
					new_activity3.target_building<- flip(0.7)? home:one_of(houses);
					new_activity3.name<-new_activity3.target_building=home?"Staying home":"Visiting other house";
					add copy(new_activity3) to:schedule;
					/////////////go home if not////////////
					if new_activity3.target_building!=home{
					new_activity4.start_hour<-new_activity3.end_hour;
					new_activity4.end_hour<-1;
					new_activity4.target_building<- home;
					new_activity4.name<-"Staying home";
					add copy(new_activity4) to:schedule;
					}			
				}
			}
		}
	/////////////////AGE/////////////////////
	action define_age{
		if(flip(old_proba)){
			age<-rnd(30)+60;
			age_group<-"old";
			if(flip(old_work_proba)){
				works<-true;
				workplace<-one_of(workabable);
			}
		}
		else{
			float not_old_proba <- 1-old_proba;
			float new_adult_proba<- adult_proba/not_old_proba;
			float new_young_proba<- young_proba/not_old_proba;
			float new_teen_proba<- teen_proba/not_old_proba;
			//float new_kid_proba<- kid_proba/not_old_proba;
			if(flip(new_adult_proba)){
				avgSpd<-13#m/#s;
				age<-rnd(19)+40;
				age_group<-"adult";
				works<-true;
				workplace<-one_of(workabable);
			}
			else{
				float not_adult_proba <-1-new_adult_proba;
				new_young_proba<- new_young_proba/not_adult_proba;
				new_teen_proba<- new_teen_proba/not_adult_proba;
				//new_kid_proba<- new_kid_proba/not_adult_proba;
				if(flip(new_young_proba)){
					avgSpd<-20#m/#s;
					age<-rnd(18)+21;
					age_group<-"young";
					works<-true;
					workplace<-one_of(workabable);	
				}
				else{
					float not_young_proba<-1-new_young_proba;
					new_teen_proba <-new_teen_proba/not_young_proba;
					//new_kid_proba <-new_teen_proba/not_young_proba;
					if(flip(new_teen_proba)){
						avgSpd<-22#m/#s;
						age<-rnd(7)+13;
						age_group<-"teen";
						if(age<16){
						sch<-one_of(schools where (each.type = "secondary"));
						
						}
						else{
							sch<-one_of(schools where (each.type = "high"));
						}
					}
					else{
						avgSpd<-16#m/#s;
						age<-rnd(6)+6;
						age_group<-"kid";
						sch<-one_of(schools where (each.type = "elementary"));
					}
				}
			}
		}
	}
	//////////////////////////Policies////////////////////
	action lockdown_schedule{
		
		loop i over: schedule{
			if(!(i.target_building.is_market or i.target_building.is_hospital)){
				i.target_building<-home;
				i.name<-"Staying home";
		}
		
		}
	}
	action no_working_schedule{
		int i<-0;
		loop while:(i<(length(schedule))){
			if(schedule[i].target_building.is_school or schedule[i].target_building.is_work or schedule[i].target_building.type="recreation"){
				schedule[i].target_building<-home;
				schedule[i].name<-"Staying home";
			}
			i<-i+1;
		}
	}
	action no_schools_schedule{
		int i<-0;
		loop while:(i<(length(schedule))){
			if(schedule[i].target_building.is_school){
				schedule[i].target_building<-home;
				schedule[i].name<-"Staying home";
			}
			i<-i+1;
		}
	}
	///////////////////////////INIT///////////////
	init{
		do define_age;
		sex<-flip(male_prob)?"M":"F";
		place<-"home";
		home<- one_of(building where(each.is_house));
		location <- any_location_in (home);
		current_building<-home;
	}
	
}


