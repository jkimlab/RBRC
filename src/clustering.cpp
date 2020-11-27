#include <iostream>
#include <fstream>
#include <string>
#include <sstream>
#include <cstdlib>
#include <vector>
#include <unordered_set>
#include <unordered_map>
#include <map>
#include <boost/algorithm/string.hpp>
using namespace std;

class DBSCAN {
	private:
		unordered_map<int,unordered_map<int,float> > db_matrix;
		unordered_map<int,int> label;
		map<int,vector<int> > db_cluster;
		unordered_set<int> neighbors;
		float epsilon;
		int minPts;

	public:
		DBSCAN(float e, int m){
			epsilon = e;
			minPts = m;
		}
		void make_matrix(int n1,int n2,float w);
		void run_cluster();
		void GetDistance(int n1,int n2);
		void GetNeighbors(int n1);
		int ExpNeighbors(int n2);
		void print_cluster();
		void print_noise();
};

int main (int argc, char** argv){
	float param_epsilon = atof(argv[1]);
	int param_minPts = atoi(argv[2]);
	char* matrix_f = argv[3];
	
	DBSCAN ds(param_epsilon,param_minPts);

	cerr << "Reading matrix.." << endl;
	ifstream fin;
	fin.open(matrix_f);
	string line;
	while(getline(fin,line)){
		if(line.at(0) == '#'){continue;}
		istringstream iss(line);
		string n1,n2,w;
		iss >> n1 >> n2 >> w;
		float weight = stof(w);
		int node1 = stoi(n1);
		int node2 = stoi(n2);
		ds.make_matrix(node1,node2,weight);
	}
	fin.close();
	cerr << "Clustring.." << endl;
	ds.run_cluster();
	cerr << "Print clusters.." << endl;
	ds.print_cluster();
	cerr << "Print noises.." << endl;
	ds.print_noise();
}


void DBSCAN::make_matrix(int n1,int n2,float w){
		db_matrix[n1][n2] = w;
		db_matrix[n2][n1] = w;
}

void DBSCAN::run_cluster(){
	unordered_map<int,unordered_map<int,float> >::iterator it;
	unordered_map<int,float>::iterator it2;
	int cluster_num = 0;
	for(it = db_matrix.begin(); it != db_matrix.end();it++){
		int n1 = it->first;
		//cout << "==> " << n1 << ": "; 
		if (label[n1] != 0){
			//cout << label[n1] << endl;
			continue;
		}
		neighbors.clear();
		GetNeighbors(n1);
		if(neighbors.size() < minPts){
			label[n1] = -1;
			//cout << "Noise" << endl;
			continue;
		}
		cluster_num++;
		label[n1] = cluster_num;
		//cout << cluster_num << endl;
		unordered_set<int>::iterator i;
		//cout << "  " << n1 << " - neighbors: ";
//		for(i = neighbors.begin();i != neighbors.end();i++){
			//cout << *i << " ";
//		}
		//cout << endl;

		int flag = 1;
		while(flag){
			flag = 0;
			for(i = neighbors.begin();i != neighbors.end();i++){
				//cout << "    " << *i << ": ";
				int n2 = *i;
				if(label[n2] == -1){
					//cout << "    -> " << n2 << "(border): " << endl;
					label[n2] = cluster_num;
				}
	
				if (label[n2] != 0){
					//cout << "    => " << n2 << ": " << label[n2] << endl;
					continue;
				}
	
				label[n2] = cluster_num;
				//cout << "    + " << n2 << ": " << label[n2]<<endl;
				flag = ExpNeighbors(n2);
				if(flag == 1){
					break;
				}
			}
		}
	}
	
	unordered_map<int,int>::iterator it3;
	for(it3 = label.begin();it3 != label.end();it3++){
		db_cluster[it3->second].push_back(it3->first);
	}
}

void DBSCAN::GetNeighbors(int n1){
	neighbors.insert(n1);
	unordered_map<int,float>::iterator it2;
	for(it2 = db_matrix[n1].begin();it2 != db_matrix[n1].end();it2++){
		int n2 = it2->first;
		if(db_matrix[n1][n2] <= epsilon){
			neighbors.insert(n2);
		}
	}
}

int DBSCAN::ExpNeighbors(int n2){
	int flag = 0;
	unordered_map<int,float>::iterator it2;
	vector<int> neighbors_tmp;
	for(it2 = db_matrix[n2].begin();it2 != db_matrix[n2].end();it2++){
		int n1 = it2->first;
		if(db_matrix[n1][n2] <= epsilon){
			neighbors_tmp.push_back(n1);
		}
	}
	if(neighbors_tmp.size() >= minPts){
		flag = 1;
//		cerr << "    Added neighbors: ";
		neighbors.insert(neighbors_tmp.begin(),neighbors_tmp.end());
//		for(int m=0;m<neighbors_tmp.size();m++){
//			cerr << neighbors_tmp[m] << " ";
//		}
//		cerr << endl;
	}
//	unordered_set<string>::iterator i;
//	cerr << "    Expanded neighbors: ";
//	for(i = neighbors.begin();i != neighbors.end();i++){
//		cerr << *i <<" ";
//	}
//	cerr << endl;
	return flag;
}

void DBSCAN::print_cluster(){
	map<int,vector<int> >::iterator it;
	ofstream fout;
	fout.open("DBC.cluster");
	for(it=db_cluster.begin();it != db_cluster.end();it++){
		if(it->first == -1){continue;}
		for(int j=0;j<(it->second).size();j++){
			fout << "DBC" << it->first << "\t" << (it->second).at(j) << endl;;
		}
	}
	fout.close();
}

void DBSCAN::print_noise(){
	map<int,vector<int> >::iterator it;
	ofstream fout;
	fout.open("DBC.noise");
	for(it=db_cluster.begin();it != db_cluster.end();it++){
		if(it->first != -1){continue;}
		for(int j=0;j<(it->second).size();j++){
			fout << (it->second).at(j) << endl;
		}
	}
	fout.close();
}
