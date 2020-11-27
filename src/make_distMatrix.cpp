#include <iostream>
#include <fstream>
#include <string>
#include <cstdlib>
#include <vector>
#include <unordered_map>
using namespace std;

struct Read {
	string rchr;
	int rstart;
	int rend;
	int rid;
	string rdir;
};

struct Ref {
	string name;
	float weight;
	string path;
};

class sitriMatrix {
	private:
		//Sitri
		unordered_map<int,unordered_map<int,float> > sitri_matrix;
		unordered_map<string,float> ref_info;
		int ref_num;
		// Reference matrix
		int len_cutoff;
		Read read_info;
		vector<Read> prev_reads;
		float weight;
	public:
		sitriMatrix(int l){
			ref_num = 0;
			len_cutoff = l;
		}
		
		void add_reference(string n, float w, string p);
		void buildMatrix(string n, float w, string p);
		void printRefInfo();
		void printMatrix();
};

int main (int argc, char** argv){
	int len_cutoff = atoi(argv[1]);
	char* input_f = argv[2];
	string ref_spc;
	float weight;
	string sorted_bed_f;
	vector<Ref> v;
	Ref ref_info;
	ifstream fin;
	fin.open(input_f);
	if(fin.fail()) cerr << "Can't open a file ("<< input_f <<")"<<endl;
	while(fin >> ref_spc >> weight >> sorted_bed_f){
		ref_info = {ref_spc,weight,sorted_bed_f};
		v.push_back(ref_info);
	}
	fin.close();

	sitriMatrix sitri(len_cutoff);
	for(int i=0;i<v.size();i++){
		cerr << ">Constructing " << v[i].name << " read distance matrix..." << endl;
		sitri.add_reference(v[i].name,v[i].weight,v[i].path);
	}

	sitri.printRefInfo();
	sitri.printMatrix();
	return 0;
}

//// DBC functions
void sitriMatrix::add_reference(string n, float w, string p){
	ref_num++;
	ref_info[n] = w;
	cerr<<">>Adding to DBC Matrix: "<<n<<endl;
	buildMatrix(n,w,p);
}

void sitriMatrix::buildMatrix(string name, float weight, string path){
	string chr, dir;
	int id, start, end, score;
	cerr << ">>>Building read distance matrix (" << name << ")... ";
	ifstream fin;
	ofstream fout;
	fout.open(name+".matrix.txt");
	fin.open(path);
	if(fin.fail()) cerr << "Can't open a file ("<< path <<")"<<endl;
	while(fin >> chr >> start >> end >> id >> score >> dir){
		int del_num = 0;
		for(int i = 0;i < prev_reads.size();i++){
			if(chr != prev_reads[i].rchr){
				prev_reads.clear();
				break;
			}
			int dist = start - prev_reads[i].rend+1;
			float weighted_dist = 0;
			if(dist > 0){
				weighted_dist = weight * float(dist);
			} else {
				weighted_dist = 0;
				dist = 0;
			}
			if(dist > len_cutoff){
				del_num++;
			} else {
				if(sitri_matrix[prev_reads[i].rid].find(id) != sitri_matrix[prev_reads[i].rid].end()){
					sitri_matrix[prev_reads[i].rid][id] += weighted_dist;
				} else if(sitri_matrix[prev_reads[i].rid].find(id) != sitri_matrix[prev_reads[i].rid].end()){
					sitri_matrix[id][prev_reads[i].rid] += weighted_dist;
				} else {
					sitri_matrix[prev_reads[i].rid][id] = weighted_dist;
				}
				//fout << prev_reads[i].rid <<"\t"<<id<<"\t"<<dist<<"\t"<<weight << "\t" << weighted_dist<<endl;
				fout << prev_reads[i].rid <<"\t"<<id<<"\t" << weighted_dist<<endl;
			}
		}
		prev_reads.erase(prev_reads.begin(),prev_reads.begin()+del_num);
		read_info = {chr,start,end,id,dir};
		prev_reads.push_back(read_info);
	}
	fin.close();
	fout.close();
	cerr << "Done" << "\n\n";
}

void sitriMatrix::printRefInfo(){
	cout<<"##Number of references: "<<ref_num<<endl;
	cout<<"##Reference weight"<<endl;
	for(unordered_map<string,float>::iterator it=ref_info.begin();it!=ref_info.end();it++){
		cout<<"####"<<it->first<<": "<<it->second<<endl;
	}
}

void sitriMatrix::printMatrix(){
	for(unordered_map<int,unordered_map<int,float> >::iterator it = sitri_matrix.begin(); it != sitri_matrix.end();it++){
		for(unordered_map<int,float>::iterator it2 = (it->second).begin(); it2 != (it->second).end();it2++){
			cout << it->first << "\t" << it2->first << "\t" << (it2->second) << endl;
		}
	}
}
