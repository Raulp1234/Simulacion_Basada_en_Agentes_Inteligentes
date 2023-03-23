/***
* Name: General
* Author: Origami
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model General


import "../models/Propagation_simulation_model.gaml"
	global{
		rgb word_color<-#black;
		
		string imagepth<-"../V2gis_data/calixto.png";
		shape_file shape_file_streets <- shape_file ("../V2gis_data/V2Roads.shp");
		shape_file shape_file_buildings<-shape_file("../V2gis_data/V2Buildings.shp");
		shape_file shape_file_stops <- shape_file ("../V2gis_data/V2Stops.shp");
		shape_file shape_file_borders <- shape_file ("../V2gis_data/V2Borders.shp");
		shape_file shape_file_bounds <- shape_file ("../V2gis_data/V2Bounds.shp");
		geometry shape <- envelope(shape_file_bounds);
		
		reflex end_simulation_reflex when:day>days_to_simulate{
		do end_simulation;
	}
		action end_simulation{
		do print_user_messages("End of the simulation.\n"+"End of "+ (day-1)+" days\nTotal contagions: "+contagions, true);
		do pause;
		do save_data;
	}
	action create_gis{
	   	create street from:shape_file_streets{
			ask cell overlapping self{
				is_street<-true;
			}
		}
		create building from: shape_file_buildings with: [type::string(read ("type")), category::string(read ("category"))]{
			ask cell overlapping self{
				cell_building<-myself;
			}
		}
		create bound from: shape_file_bounds;
		create border from: shape_file_borders;
		create bus_stop from: shape_file_stops;
	   }
	init{
		do create_gis;
		bool x<-true;
		map<string, unknown> aa<- [
		"How many people will be on the simulation?"::500,
		"Days to simulate"::30,
		"Initial infeccious percentile"::percentile_inf_people,
		"Virus data csv file"::csv_virusData_file
		 ];
		loop while:x{
		 aa <- user_input([
		"How many people will be on the simulation?"::500,
		"Days to simulate"::30,
		"Initial infeccious percentile"::percentile_inf_people,
		"Virus data csv file"::csv_virusData_file
		 ]);
		 if(int(aa["Days to simulate"])<1 or
		 	(int(aa["How many people will be on the simulation?"])<1) or 
		 	(float(aa["Initial infeccious percentile"])>100) or
		 	(float(aa["Initial infeccious percentile"])=0) or
		 	(!contains(string(aa at "Virus data csv file"),".csv"))
		 ){
		 	do print_user_messages("Incorrect parameters, please select another configuration",true);
		 }
		 else{
		 	x<-false;
		 }
		} 
		
		/////////////////////////VIRUS DATA FROM GIVEN FILE/////////////////////////
		matrix vd<-matrix(csv_file(string(aa at "Virus data csv file"), ",", false));
		//write(vd);
		map<string, unknown> virusdata<-create_map(row_at(vd,0),row_at(vd,1));
				
		create virus_type{
		name<-virusdata["name"];
		//write(name);
		contamination_rate<-virusdata["contamination_rate"];
		//write("contamination_rate" + contamination_rate);
		prob<-virusdata["contagion_probability"];
		//write(prob);
		contamination_radius<-virusdata["contamination_radius_(dm)"];
		//write(contamination_radius);
		}
		
		avg_latent_time<-int(virusdata["average_incubation_time"]);
		//write(avg_latent_time);
		avg_infeccious_time<-int(virusdata["average_infeccious_time"]);
		//write(avg_infeccious_time);
		asyn_prob<-virusdata["asymphtomatic_probability"];
		//write(asyn_prob);
		get_symph_prob<-virusdata["symphtomatic_probability_if_asymph"];
		//write(get_symph_prob);
		min_get_symph_time<-virusdata["min_symphtomatic_transition_time"];
		//write(min_get_symph_time);
		get_serious_condition_prob<-virusdata["get_serious_condition_probability"];
		//write(get_serious_condition_prob);
		get_critical_condition_prob<-virusdata["get_critical_condition_porbability"];
		//write(get_critical_condition_prob);
		die_prob<-virusdata["death_probability"];
		//write(die_prob);
		inm_proba<-virusdata["inmunity_probability_after_recover"];	
		//write(inm_proba);
		////////////////////////////////////////////////////
		days_to_simulate<-int(aa["Days to simulate"]);
		nb_people<-int(aa["How many people will be on the simulation?"]);
		prob_inf_people<-float(aa["Initial infeccious percentile"])/100;
		write "======================================";
	write("Start of the simulation.\nDays to simulate: "+(days_to_simulate)+"\nInicial total people: "+(nb_people));
	write "======================================";
	}
	}
	experiment General_Experiment virtual:true {	
		
		parameter "Required face mask use" var:face_masks category:"Contagion policy";
		parameter "Desinfection quality" var: desinfection_rate category:"General";
		user_command "End simulation" action:end_simulation category: "General";
		
		
	output {
	    monitor Day value: day refresh: true;	 
        monitor Time value: hour refresh: true;
        monitor Day_of_the_Week value:week_day refresh:true;
        monitor Cases value:contagions refresh:true;
        monitor In_Serious_Condition value:nb_serious_condition refresh:true;
        monitor In_Critical_Condition value:nb_critical_condition refresh:true;
        monitor Total_Deaths value:total_deaths refresh:true;
		    display main_display background:#white{
				grid cell lines:#white;
				species street aspect:base transparency:0.5;
				image file:imagepth refresh: false;
				species public_transportation aspect: base;
				species building aspect:base transparency:0.6;
				species SEIR_people aspect:SEIR_base transparency:0.1;
				
				
			 	overlay position: { 0, 0.8 } size: { 200 #px, 150 #px } background: #black {
					draw inmune_color at: { 20#px, 30#px } size: 20#px;
					draw "Inmune" at:{45#px, 34#px} font: font("Helvetica", 20) color:word_color;
					draw susceptible_color at: { 20#px, 57#px } size: 20#px;
					draw "Susceptible" at:{45#px, 59#px} font: font("Helvetica", 20) color:word_color;
					draw exposed_color at: { 20#px, 82#px } size: 20#px;
					draw "Exposed" at:{45#px, 84#px} font: font("Helvetica", 20) color:word_color;
					draw infeccious_asym_color at: { 20#px, 107#px } size: 20#px;
					draw "Asymphtomatic" at:{45#px, 109#px} font: font("Helvetica", 20) color:word_color;
					draw infeccious_color at: { 20#px, 132#px } size: 20#px;
					draw "Infeccious" at:{45#px, 134#px} font: font("Helvetica", 20) color:word_color;
					draw quarentined_color at: { 20#px, 157#px } size: 20#px;
					draw "Quarentined" at:{45#px, 159#px} font: font("Helvetica", 20) color:word_color;	
				}
				
		}
		display Structure_Display {
				grid cell lines:#white;
				
				species street aspect:base; 
				species building aspect: structural;
				species public_transportation aspect: base;
				species SEIR_people aspect:structural;
				
				overlay position: { 0, 0.8 } size: { 200 #px, 150 #px } background: #black {
					draw house_color at: { 20#px, 30#px } size: 20#px;
					draw "House" at:{45#px, 30#px} font: font("Helvetica", 20) color:word_color;
					draw hospital_color at: { 20#px, 55#px } size: 20#px;
					draw "Hospital" at:{45#px, 55#px} font: font("Helvetica", 20) color:word_color;
					draw market_color at: { 20#px, 80#px } size: 20#px;
					draw "Market" at:{45#px, 80#px} font: font("Helvetica", 20) color:word_color;
					draw work_color at: { 20#px, 105#px } size: 20#px;
					draw "Workplace" at:{45#px, 105#px} font: font("Helvetica", 20) color:word_color;
					draw recreation_color at: { 20#px, 130#px } size: 20#px;
					draw "Recreation place" at:{45#px, 130#px} font: font("Helvetica", 20) color:word_color;	
					draw school_color at: { 20#px, 155#px } size: 20#px;
					draw "School" at:{45#px, 155#px} font: font("Helvetica", 20) color:word_color;
					draw closed_color at: { 20#px, 180#px } size: 20#px;
					draw "Closed" at:{45#px, 180#px} font: font("Helvetica", 20) color:word_color;
				}
								
		}
		/*
		display "People ages" {
			chart "people ages" type: pie size:{1,0.5} position: {0, 0}{
				data "Old" value: (SEIR_people count( each.age_group = "old")) color:#gray;
				data "Adult" value:(SEIR_people count( each.age_group = "adult")) color:#blue;
				data "Young"value:(SEIR_people count( each.age_group = "young")) color:#orange;
				data "Teen" value:(SEIR_people count( each.age_group = "teen")) color:#yellow;
				data "Kid" value:(SEIR_people count( each.age_group = "kid")) color:#green;
			}
		}*/
		display "Population Contagions"{
			chart "Total contagions per place" type: pie size:{1,0.5} position: {0, 0} background:#white style: exploded {
				data "Outdoors" value:nb_outdoor_contagions color:#black;
				data "Markets" value:nb_market_contagions color:#lightgreen;
				data "Schools" value:nb_school_contagions color:#lightpink;
				data "Recreations" value:nb_recreation_contagions color:#orange;
				data "Houses" value:nb_house_contagions color:#gray;
				data "Workplaces" value:nb_work_contagions color:#blue;
				data "Hospitals" value:nb_hospital_contagions color:#red;
				data "Buses" value:nb_bus_contagions color:rgb (36, 200, 200,255);
			}
			chart "Number of exposed people per 100 people" type: series size: {1,0.5} position: {0, 0.5} {
				data "Contagied Percentile" value: contagion_percentile color: #red ;
			}
		}
		display "SEIR Status" refresh: every(2#cycles) {
			chart "Amount people by SEIR status" type: series size:{1,0.5} position: {0, 0} background:#white{
				data "Infected" value: length((SEIR_people where (each.SEIR_Status="Infected")) where(not each.asyn)) color:#red ;
				data "Infected asymphtomatic" value: length((SEIR_people where (each.SEIR_Status="Infected")) where(each.asyn)) color:#orange ;
				data "Exposed" value: length(SEIR_people where (each.SEIR_Status="Exposed")) color:#yellow ;
				data "Inmune" value: length(SEIR_people where (each.SEIR_Status="Inmune")) color:#blue ;
				data "Susceptible" value: length(SEIR_people where (each.SEIR_Status="Susceptible")) color:#green ;
				data "Quarentined" value: length(SEIR_people where (each.SEIR_Status="Quarentined")) color:#violet ;
				data "Dead" value:total_deaths color:#black;
			}
			chart " Average Exposed people per Infected" type: series size: {1,0.5} position: {0, 0.5} {
				data "Exposed person by each infected person" value: contagied_per_infected color: #red ;
			}
			
			}
		display "Contagion history" refresh: every(2#cycles){
			chart "Cases per day" type: histogram position:{0,0} size:{1,0.5}{
					int i<-0;
					loop while:(i<days_to_simulate){
						data "day "+(i+1) value:(length(daily_cases)<i+1?0:daily_cases[i]) accumulate_values:false;
						i<-i+1;
					}
			}
			chart "Deaths per day" type: histogram position:{0,0.5} size:{1,0.5}{
					int i<-0;
					loop while:(i<days_to_simulate){
						data "day "+(i+1) value:(length(daily_deaths)<i+1?0:daily_deaths[i]) accumulate_values:false;
						i<-i+1;
					}
			}
		}
		display "Contagions data" refresh: every(2#cycles){
			chart"Contagions per age and sex" type: histogram position:{0,0} size:{1,0.5}{
				int i<-0;
				string key;
					loop while:(i<length(contagions_by_sex_and_age.keys)){
						key<-contagions_by_sex_and_age.keys[i];
						data key+" M" value:contagions_by_sex_and_age[key][0] color:#blue;
						data key+" F" value:contagions_by_sex_and_age[key][1] color:#red;
						i<-i+1;
					}
			}
			chart "Contagions per activity" type: histogram position:{0,0.5} size:{1,0.5}{
				int i<-0;
				string key;
					loop while:(i<length(contagions_by_activity.keys)){
						key<-contagions_by_activity.keys[i];
						data key value:contagions_by_activity[key];
						i<-i+1;
					}
			}
		}
	}
	
	}
/* Insert your model definition here */

