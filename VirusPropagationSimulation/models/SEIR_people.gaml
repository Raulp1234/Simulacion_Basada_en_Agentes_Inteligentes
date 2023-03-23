/***
* Name: CovidPeople
* Author: Origami
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model SEIR_people
import "../models/Propagation_simulation_model.gaml"
import "../models/People_Species.gaml"
species virus_type{
	string name;
	float contamination_rate min:0 max:1;
	float prob min:0 max:1;
	float contamination_radius min:0 max:100;
	aspect base{
		
	}
	init{
		
	}
}
// Definition of Grid species to discretize space
grid cell width: nb_cols height: nb_rows neighbors: 8 parallel:true{
		bool is_street<-false; 
		float aux;
		virus_type virus;
		building cell_building;
		float contamination <- 0.0 max: 1.0 min:0.0;
	rgb color <- rgb(255 ,int( 255* (1 - contamination)), int(255 * (1 - contamination))) update: rgb(255 ,int( 255 * (1 - contamination)), int(255 *(1 - contamination))) ;
	reflex clean when:every(8# cycles){
		if(is_street){
			contamination<-contamination-cleanrate;
		}
		contamination<-contamination-cleanrate;
	}
	action contaminate(float distance, virus_type virust){
		float mult<-face_masks?0.15:0.9;
			self.virus<-virust;
			if(distance < virus.contamination_radius*3){
		contamination<- contamination+virus.contamination_rate*mult;
			}
			else if(distance < virus.contamination_radius*6){
				aux<-virus.contamination_rate/2.0;
			contamination <- contamination+aux*mult;
			
			}
			else{
				aux<-virus.contamination_rate/4.0;
				contamination<- contamination+aux*mult;
			}
	}
	
	}
species SEIR_people skills:[moving] parent:People parallel:true{
	rgb SEIR_color;
	
	int contagion_time;
	string SEIR_Status;
	
	
	
	///////////////////////////////INFECTED///////////////////////////////////
	virus_type virus;
	virus_type vt;
	float go_to_hosp_prob<-global_go_to_hosp_prob;
	int current_infeccious_time;
	int infeccious_time<-rnd(4)+avg_infeccious_time-2;
	string condition<-"healthy";
	bool asyn<-false;
	
	reflex spread_disease when:(SEIR_Status="Infected"or SEIR_Status="Quarentined"){
		list<cell> cells;
		if(inside_building){
			cells <- cell at_distance(virus.contamination_radius) where(each.cell_building=current_building);
		}
		else{
			cells <- cell at_distance(virus.contamination_radius) where(each.is_street);
		}
		ask(cells){
			do contaminate distance:self.location distance_to myself.myCell.location virust:myself.virus;
		}
	}
	reflex go_to_hospital when:SEIR_Status="Infected"  and flip(go_to_hosp_prob) and !asyn{
		
		
		if(length(schedule)<2){
		activity new_activity;
		create activity{
			start_hour<-(int(simulation_date.hour))<24?(int(simulation_date.hour))+1:0;
			end_hour<-start_hour+2;
			target_building<-(building where(each.is_hospital)) closest_to(self);
			name<-"Going to hospital";
			new_activity<-self;
		}
		add new_activity to:schedule at:1;
		}
		else{
			loop x over:schedule{
				x.name<-"Going to hospital";
				x.target_building<-(building where(each.is_hospital)) closest_to(self);
				x.start_hour<-(int(simulation_date.hour))<24?(int(simulation_date.hour))+1:0;
				x.end_hour<-(x.start_hour)+2;
			}
		}
	}
	reflex get_test when:SEIR_Status="Infected" and (inside_building and current_building.is_hospital) and !asyn{
		SEIR_Status<-"Quarentined";
		SEIR_color<-#violet;
		do stay_home;
	}
	reflex get_serious when:(SEIR_Status="Infected" or SEIR_Status="Quarentined") and condition="sick" and !asyn{
			if(flip(get_serious_condition_prob) or age>70){
				condition<-"serious";
				go_to_hosp_prob<-1;
		}
	}
	reflex get_critical when:(SEIR_Status="Infected" or SEIR_Status="Quarentined") and condition="serious"{
			if(flip(get_serious_condition_prob)){
				condition<-"critical";
		}
	}
	reflex get_dead when:(SEIR_Status="Infected" or SEIR_Status="Quarentined") and condition="critical"{
			if(flip(die_prob)){
				total_deaths<-total_deaths+1;
				put (daily_deaths[day-1]+1) in:daily_deaths at:(day-1);
				write("New Death: "+self+ ", "+age+" years old, "+sex);
				do die;
				
			}
		}
	reflex heal when:(SEIR_Status="Infected" or SEIR_Status="Quarentined") and (current_infeccious_time=infeccious_time){
		if(simulation_date.hour=contagion_time){
			if(flip(inm_proba)){
			SEIR_Status<-"Inmune";
			SEIR_color<-inm_color;
			protection<-1.0;
			virus<-nil;
			condition<-"healthy";
		}
		else{
			SEIR_Status<-"Susceptible";
			SEIR_color<-#green;
			protection<-(rnd(29)/100)+0.7;
			virus<-nil;
			condition<-"healthy";
		}
		current_infeccious_time<-0;
	}
	
	}
	
	
	action updt_inf_time{
		current_infeccious_time<-current_infeccious_time+1;
		if(current_infeccious_time>min_get_symph_time and simulation_date.hour=contagion_time){
			if(flip(get_symph_prob)){
				asyn<-false;
			}
		}
	}
	//////////////////////////QuARENTINED/////////////////
	action stay_home{
		int i<-0;
		loop while:(i<(length(schedule))){
			schedule[i].target_building<-home;
			schedule[i].name<-"Staying home";
			i<-i+1;
		}
	}
	/////////////////////////EXPOSED////////////////////////
	int current_latent_time<-0;
	int latent_time<-rnd(2)+avg_latent_time -1;
	reflex get_infeccious when:SEIR_Status="Exposed"{
		if(latent_time=current_latent_time and (simulation_date.hour=contagion_time)){
			SEIR_Status<-"Infected";
			if(flip(asyn_prob)){
				asyn<-true;
				SEIR_color<-inf_asym_color;
			}
			else{
			SEIR_color<-inf_color;
			condition<-"sick";
				
			}
			current_latent_time<-0;
			total_inf_people<-total_inf_people+1;
		}	
	}
	action updt_latent_time{
		current_latent_time<-current_latent_time+1;
	}
	
	////////////////////////////SUSCEPTIBLE//////////////////////////////////////////
	float viral_charge max:1.0;
	float sex_influence<-sex="M"?0.2:0.5;
	float protection<-(rnd(5.0)/10 + sex_influence) * 1-age_influences[age_group] max:0.99;
	float income_charge<-0.0 min:0.0;
	
	reflex expose when:SEIR_Status="Susceptible"{
		income_charge <-(myCell.contamination*(1-protection))/10;
		viral_charge <- viral_charge + income_charge;
		//SEIR_color<-rgb(128,128,int(128*(1-viral_charge)));
		if(viral_charge>=1 and income_charge>0){
			do get_fully_exposed;
			
		}
	}
	action get_fully_exposed {
		if(flip(beta)){
			contagion_time<-simulation_date.hour;
			SEIR_Status<-"Exposed";
			SEIR_color<-exp_color;
			virus<-myCell.virus;
			////////updt contagions///////
			contagions<-contagions+1;
			//////////////////updt daily contagions
			put (daily_cases[day-1]+1) in:daily_cases at:(day-1);
			//////////////////////////updat sex and age list
			list<int> new_list<-contagions_by_sex_and_age[self.age_group];
			put new_list[(sex="M"?0:1)]+1 in:new_list at:(sex="M"?0:1);
			add new_list at:age_group to:contagions_by_sex_and_age;
			///////////////////////////updt activity contagions///////////////
			put contagions_by_activity[schedule[0].name]+1 in:contagions_by_activity at:schedule[0].name;
			//////////////////////////updt contagions per place///////////////////
			string place;
			if(current_building=nil){
				if(in_bus){
					nb_bus_contagions<-nb_bus_contagions+1;	
					place<- "bus";
				}
				else{
					nb_outdoor_contagions<-nb_outdoor_contagions+1;
					place<- "outdoors";
				}
			}
			else if(current_building.is_house){
				nb_house_contagions<-nb_house_contagions+1;
				place<- "house";
			}
			else if(current_building.is_school){
				nb_school_contagions<-nb_school_contagions+1;
				place<- "school";
			}
			else if(current_building.is_hospital){
				nb_hospital_contagions<-nb_hospital_contagions+1;
				place<- "hospital";
			}
			else if(current_building.is_recreation){
				nb_recreation_contagions<-nb_recreation_contagions+1;
				place<- "recreation";
			}
			else if(current_building.is_market){
				nb_market_contagions<-nb_market_contagions+1;
				place<- "market";
			}
			else{
				nb_work_contagions<-nb_work_contagions+1;
				place<- "work";
			}
			write("New Contagion: "+self+ ", "+age+" years old, "+sex+ ", "+ place);
	}
	}
	
	//////////////////////////QUARENTINED//////////////////
	
	

	///////////////////////INIT////////////////////////////
	init{
		
		if(flip(prob_exp_people)){
		SEIR_Status<-"Exposed";
		SEIR_color<-exp_color;
		loop while:(virus=nil){
		 vt<-one_of(virus_type);
		if(flip(vt.prob)){
			virus<-vt;
			}
			
			}
		}
		else if(flip(prob_inf_people)){
			total_inf_people<-total_inf_people+1;
			SEIR_Status<-"Infected";
			contagion_time<-rnd(24);
			SEIR_color<-inf_color;
			total_inf_people<-total_inf_people+1;
			condition<-"sick";
			if(flip(asyn_prob)){
				asyn<-true;
				SEIR_color<-inf_asym_color;	
			}
			loop while:(virus=nil){
		 vt<-one_of(virus_type);
		if(flip(vt.prob)){
			virus<-vt;
			}
			
			}
		}
		else{
			SEIR_Status<-"Susceptible";
			//SEIR_color<-rgb(128,128,128);
			SEIR_color<-#green;
		if(flip(alpha)){
			SEIR_Status<-"Inmune";
			SEIR_color<-inm_color;
		}
		}
		}
		
	////ASPECTS
	aspect SEIR_base{
		draw circle(people_size) color:SEIR_color border:true;
		if(face_masks){
		draw (people_size*0.5+(people_size*0)) around circle(people_size) color:#blue border: #black;
		}
	}
	aspect structural{
		draw circle(people_size) color:#gray border:#black;	
	}
} 
