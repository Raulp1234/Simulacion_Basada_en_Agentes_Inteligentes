/***
* Name: NewModel
* Author: Origami
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Propagation_simulation_model
import "../models/SEIR_people.gaml"
import "../models/Activities.gaml"
	global{
	////////////////GENERAL/////////////////
	int nb_people<-500;
	float people_size<-5;
	int simulation_speed<-5;
	int	nb_cols<-100;
	int nb_rows<-100;
	string csv_path<-"../includes/virusData.csv";
	file csv_virusData_file <- csv_file(csv_path, ",", false);
	///////////////////////SEIR////////////////////////
	string desinfection_rate init: "Normal" among: ["High", "Normal", "Poor", "None"];
	float max_contagied_per_infected;
	float cleanrate<-0.06;
	float percentile_inf_people<-0.5 min:0.0 max:100.0;
	float prob_inf_people <-0.005;
	float prob_exp_people<-0.00 min:0.0 max:1.0;
	float beta<-0.05 min:0.0 max:1.0;
	float alpha <- 0.1 min:0.0 max:1.0;
	rgb inf_color<-#red;
	rgb exp_color<-rgb(255,255,0);
	rgb inm_color<-#blue;
	rgb inf_asym_color<-rgb (255, 128, 0,255);
	int contagions<-0;
	int daily_contagions<-0;
	int nb_hospital_contagions;
	int nb_market_contagions;
	int nb_school_contagions;
	int nb_house_contagions;
	int nb_work_contagions;
	int nb_recreation_contagions;
	int nb_outdoor_contagions;
	int nb_bus_contagions;
	float contagied_per_infected<-0.0;
	float contagion_percentile<-0.0;
	int total_inf_people<-0;
	int avg_latent_time min:0;
	int avg_infeccious_time min:0;
	float get_symph_prob min:0 max:1;
	int min_get_symph_time min:0;
	float get_serious_condition_prob min:0 max:1;
	float get_critical_condition_prob min:0 max:1;
	float die_prob min:0 max:1;
	float global_go_to_hosp_prob<-0.001;
	float inm_proba min:0 max:1;
	int nb_serious_condition -> {length(SEIR_people where(each.condition="serious"))};
	int nb_critical_condition -> {length(SEIR_people where(each.condition="critical"))};
	int total_deaths<-0;
	list<int> daily_cases<-[];
	list<int> daily_deaths<-[];
	bool face_masks<-false;
	float asyn_prob min:0 max:1;
	string mode;
	map<string,float>age_influences<-["kid"::0.0,"teen"::0.1,"young"::0.2,"adult"::0.5,"old"::0.8];
	
	map<string,list<int>> contagions_by_sex_and_age<-["kid"::[0,0],"teen"::[0,0],"young"::[0,0],"adult"::[0,0],"old"::[0,0]];
	map<string,int>contagions_by_activity<-["Staying home"::0,"Shoping"::0, "Studying"::0, "Working"::0, "Visiting other house"::0,"Going to hospital"::0, "Recreating"::0, "Wandering"::0];
	//////////////////AGE & SEX////////////////////////////
	float kid_proba<-0.09;
	float teen_proba<-0.07;
	float young_proba<-0.20;
	float adult_proba<-0.32;
	float old_proba<-0.21;
	float old_work_proba<-0.5;
	int nb_old_people update:length(SEIR_people where (each.age_group="old"));
	int nb_adult_people update:length(SEIR_people where (each.age_group="adult"));
	int nb_young_people update:length(SEIR_people where (each.age_group="young"));
	int nb_teen_people update:length(SEIR_people where (each.age_group="teen"));
	int nb_kid_people update:length(SEIR_people where (each.age_group="kid"));
	float male_prob<-0.45;
	///////////////////////////////TIME DATA///////////////////////////////
	int days_to_simulate<-30;
	date start_date <- date([date("now").year, date("now").month, date("now").day, 0, 0, 0]);
    date simulation_date <- start_date;
    int day;     
	int week_day;
	string hour update: string(simulation_date, "HH:mm:ss");
	///////////////////////////GIS DATA///////////////////////////////////////////
	/* 
		string imagepth<-"../V2gis_data/calixto.png";
		shape_file shape_file_streets <- shape_file ("../V2gis_data/V2Roads.shp");
		shape_file shape_file_buildings<-shape_file("../V2gis_data/V2Buildings.shp");
		shape_file shape_file_stops <- shape_file ("../V2gis_data/V2Stops.shp");
		shape_file shape_file_borders <- shape_file ("../V2gis_data/V2Borders.shp");
		shape_file shape_file_bounds <- shape_file ("../V2gis_data/V2Bounds.shp");
		geometry shape <- envelope(shape_file_bounds);
	*/
	
				/* 
		string imagepth<-"../V3gis_data/Militar.png";
		shape_file shape_file_streets <- shape_file ("../V3gis_data/V3Roads.shp");
		shape_file shape_file_buildings<-shape_file("../V3gis_data/V3Buildings.shp");
		shape_file shape_file_stops <- shape_file ("../V3gis_data/V3Stops.shp");
		shape_file shape_file_borders <- shape_file ("../V3gis_data/V3Borders.shp");
		shape_file shape_file_bounds <- shape_file ("../V3gis_data/V3Bounds.shp");
		geometry shape <- envelope(shape_file_bounds);
		*/
	
	////////////////////////////////////BUILDINGS//////////
	list<building>houses;
	list<building>workss;
	list<building>recreations;
	list<building>hospitals;
	list<building>markets;
	list<building>schools;
	list<building>workabable;
	list<building>allowed;
	////////////////////////////Experiment////////////////
	
	image_file infeccious_color <- image_file("../V2images/V2Infeccious.png");
	image_file infeccious_asym_color <- image_file("../V2images/V2InfecciousAsym.png");
	image_file exposed_color <- image_file("../V2images/V2Exposed.png");
	image_file susceptible_color <- image_file("../V2images/V2Susceptible.png");
	image_file inmune_color <- image_file("../V2images/V2Insusceptible.png");
	image_file quarentined_color <- image_file("../V2images/V2Quarentined.png");
	
	image_file house_color<-image_file("../V2images/V2House.png");
	image_file hospital_color<-image_file("../V2images/V2Hospital.png");
	image_file school_color<-image_file("../V2images/V2School.png");
	image_file market_color<-image_file("../V2images/V2Market.png");
	image_file work_color<-image_file("../V2images/V2Work.png");
	image_file recreation_color<-image_file("../V2images/V2Recreation.png");
	image_file closed_color<-image_file("../V2images/V2Closed.png");
	//////////////////////////////REFLEXES///////////////////
	reflex update_max_Ro{
		max_contagied_per_infected<-max_contagied_per_infected<contagied_per_infected?contagied_per_infected:max_contagied_per_infected;
	}
	reflex update_cleanrate{
		if(desinfection_rate = "High"){
			cleanrate<-0.8;
		}
		else if(desinfection_rate = "Poor"){
			cleanrate<-0.01;
		}
		else if(desinfection_rate = "None"){
			cleanrate<-0.0001;
		}
	}
	reflex update_cont_porc{
		if(contagions>0){
		contagion_percentile<- contagions*100/length(SEIR_people);
		
		}
		if(total_inf_people>0){
			contagied_per_infected<-contagions/total_inf_people;
		}
			
	}
	reflex update_nb_minutes {
	   	simulation_date <- simulation_date plus_minutes simulation_speed;
	   }
	reflex update_day_count when: hour="00:00:00"{
		day<-day+1;
		week_day<-week_day+1;
		add 0 to:daily_cases;
		add 0 to:daily_deaths;
		if (week_day=8){
			week_day<-1;
		}
		if(week_day = 6 or week_day=7){
			ask SEIR_people{
				do create_weekend_schedule;
			}
		}
		else{
			ask SEIR_people{
				do create_schedule;
			}
		}
		////////////////////////////Policies////////////////
		if(mode="lockdown"){
			ask SEIR_people{
				do lockdown_schedule;
			}
		}
		else if(mode="No schools"){
			ask SEIR_people{
				do no_schools_schedule;
			}
		}
		else if(mode="No workplaces"){
			ask SEIR_people{
				do no_working_schedule;
			}
		}
		///////////////SEIR/////////
		ask (SEIR_people where(each.SEIR_Status="Exposed")){
			do updt_latent_time;
		}
		ask (SEIR_people where(each.SEIR_Status=("Infected"))){
			do updt_inf_time;
		}
		ask (SEIR_people where(each.SEIR_Status=("Quarentined"))){
			do updt_inf_time;
			do stay_home;
		}
		
	}
	reflex hour_change when: simulation_date.minute=0{
		ask SEIR_people{
			do check_schedule;
		}
	}	
	reflex create_transport when:every(40# cycles) and simulation_date.hour>6 and mode!="lockdown"{
		create public_transportation{
			loop times:3{
				add one_of(bus_stop) to:stops;
			}
			location<-(border closest_to(stops[0])).location;
			next_stop <-stops[0].get_street_point();
		}
	}
	
	/////////////////ACTIONS////////////
	
	action create_buildings_lists{
		houses<-(building where(each.is_house));
		markets<-(building where(each.is_market));
		schools<-(building where(each.is_school));
		hospitals<-(building where(each.is_hospital));
		recreations<-(building where(each.is_recreation));
		workss<-(building where(each.is_work));
		workabable<-building where(not each.is_house and not each.is_recreation);
	}
	 
	
	
	
	action save_data{
		if(!file_exists("../result/virusPropagationStatistics.csv")){
			save [
      		"Date",
      		"Mode",
      		"Days to simulate",
      		"nb_of_people",
      		"Initial_infected_proba",
      		"Initial_inmune_proba",
      		"face masks",
      		"desfinfection quality",
      		
      		"Cases",
      		"Total_Deaths",
      		"nb_outdoor_contagions",
      		"nb_market_contagions",
      		"nb_school_contagions",
      		"nb_recreation_contagions",
      		"nb_house_contagions",
      		"nb_work_contagions",
      		"nb_hospital_contagions",
      		"nb_bus_contagions",
      		"Infeccious_at_end",
      		"Inmune_at_end",
      		"Susceptible_at_end",
      		"Exposed_at_end",
      		"Quarentined_at_end",
      		"Highest basic reproducion number",
      		"Virus_name",
      		"contamination_rate",
      		"contagion_probability",
      		"contamination_radius_(dm)",
      		"average_incubation_time",
      		"average_infeccious_time",
      		"asymphtomatic_probability",
      		"symphtomatic_probability_if_asymph",
      		"min_symphtomatic_transition_time",
      		"get_serious_condition_probability",
      		"get_critical_condition_porbability",
      		"death_probability",
      		"inmunity_probability_after_recover"
      		
      		     ]		to: "../result/virusPropagationStatistics.csv" type: "csv";
		}
      		save [
      	    date("now"),
      		mode,
      		days_to_simulate,
      		nb_people,
      		prob_inf_people,
      		alpha,
      		face_masks,
      		desinfection_rate,
      		
      		contagions,
      		total_deaths,
      		nb_outdoor_contagions,
      		nb_market_contagions,
      		nb_school_contagions,
      		nb_recreation_contagions,
      		nb_house_contagions,
      		nb_work_contagions,
      		nb_hospital_contagions,
      		nb_bus_contagions,
      		length(SEIR_people where (each.SEIR_Status="Infected")),
      		length(SEIR_people where (each.SEIR_Status="Inmune")),
      		length(SEIR_people where (each.SEIR_Status="Susceptible")),
      		length(SEIR_people where (each.SEIR_Status="Exposed")),
      		length(SEIR_people where (each.SEIR_Status="Quarentined")),
      		max_contagied_per_infected,
      		
      		one_of(virus_type).name,
      		one_of(virus_type).contamination_rate,
      		alpha,
      		one_of(virus_type).contamination_radius,
      		avg_latent_time,
      		avg_infeccious_time,
      		asyn_prob,
      		get_symph_prob,
      		min_get_symph_time,
      		get_serious_condition_prob,
      		get_critical_condition_prob,
      		die_prob,
      		inm_proba
      		
      		
      		      ]		to: "../result/virusPropagationStatistics.csv" type: "csv" rewrite: false; 
	}
	action print_user_messages(string mes, bool use_notification_window){
	   	if(use_notification_window){
	   	   do tell message: mes;
	   	}
	    write "======================================";	
	    write mes;
	    write "======================================";	
	   }
	   
	   
	   
	   
	   	////////////////////////////////////////INIT////////////////////////////////
	init{
		
		do create_buildings_lists;
		
		
		
		create SEIR_people number:nb_people;
		ask SEIR_people{
			do create_schedule;
		}
		///////////////////////////////////No schools eperiment//////////////////////
		if(mode="No schools"){
			ask building where(each.is_school){
				color<-#black;
			}
		}
		/////////////////////////////No works experiment///////////////////////////
		else if(mode="No workplaces"){
			ask building where(not (each.is_hospital or each.is_market or each.is_house or each.type="park")){
			color<-#black;
			}
		}
		/////////////////////////////////////////LOCKDOWN//////////////////////////////////
	else if(mode="lockdown"){
			ask building where(not (each.is_hospital or each.is_market or each.is_house)){
			color<-#black;
		}
		
		}
	}
	  /////////////END OF GLOBAL////////////// 
	}
	
	//////////////////////SPECIES//////////////////
	
	species bound
{
	aspect base{
   	   draw shape color: rgb (192, 192, 192);
   }	
}
	
	species street{
		string name;
		aspect base{
			draw shape at: {location.x,location.y,location.z} 
			color:#black;
		}
	}
	species building{
		bool is_school<-false;
		bool is_house<-false;
		bool is_hospital<-false;
		bool is_work<-false;
		bool is_recreation<-false;
		bool is_market<-false;
		string type;
		string category;
		rgb color;
		aspect base{
			draw shape at: {location.x,location.y,location.z} 
			color:#gray border:#black;
		}
		aspect structural{
			draw shape at: {location.x,location.y,location.z}
			color:color; 
			
		}
		init{
			switch category{
				match "house"{
					is_house<-true;
					color<-#gray;
				}
				match "work"{
					is_work<-true;
					color<-#blue;
				}
				match"hospital"{
					is_hospital<-true;
					color<-#red;
				}
				match "market"{
					is_market<-true;
					color<-#lightgreen;
				}
				match "school"{
					is_school<-true;
					color<-#lightpink;
				}
				match "recreation"{
					is_recreation<-true;
					color<-#orange;
				}
			}
		}
	}
	
	
	
	
/* Insert your model definition here */

