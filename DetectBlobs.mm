#import <Foundation/Foundation.h>
#import <vector>

void search(std::vector<std::vector<unsigned int>> *connections, unsigned int target, long *use, int depth) {
	
	std::vector<unsigned int> *list = &((*connections)[target]);
	for(int k=0; k<list->size(); k++) {
		unsigned int tmp = (*list)[k];
		if(use[tmp]==-1) {
			use[tmp] = depth;
			search(connections,tmp,use,depth);
		}
	}
}

int main(int argc, char *argv[]) {
	@autoreleasepool {
		
		double then = CFAbsoluteTimeGetCurrent();
		srandom(then);

		NSString *src = [NSString stringWithContentsOfFile:@"./marge.obj" encoding:NSUTF8StringEncoding error:nil];
		NSArray *lines = [src componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
		
		NSCharacterSet *whitespaces = [NSCharacterSet whitespaceCharacterSet];
				
		std::vector<float> v;
		std::vector<unsigned int> f;
		
		for(int k=0; k<[lines count]; k++) {
			NSArray *arr = [lines[k] componentsSeparatedByCharactersInSet:whitespaces];
			if([arr count]>0) {
				if([arr[0] isEqualToString:@"v"]) {
					
					float x = [arr[1] doubleValue];
					float y = [arr[2] doubleValue];
					float z = [arr[3] doubleValue];
					
					v.push_back(x);
					v.push_back(y);
					v.push_back(z);
					
					v.push_back([arr[4] doubleValue]);
					v.push_back([arr[5] doubleValue]);
					v.push_back([arr[6] doubleValue]);
				}
				else if([arr[0] isEqualToString:@"f"]) {
					f.push_back([arr[1] intValue]-1);
					f.push_back([arr[2] intValue]-1);
					f.push_back([arr[3] intValue]-1);
				}
			}
		}
				
		unsigned long verticesNum = v.size()/6;
		unsigned long facesNum = f.size()/3;

		std::vector<std::vector<unsigned int>> connections;
		for(int n=0; n<verticesNum; n++) {
			connections.push_back({});
		}
		
		for(int n=0; n<facesNum; n++) {
			
			unsigned int faces[3] = {
				f[n*3+0],
				f[n*3+1],
				f[n*3+2]
			};
			
			connections[faces[0]].push_back(faces[1]);
			connections[faces[0]].push_back(faces[2]);
			
			connections[faces[1]].push_back(faces[0]);
			connections[faces[1]].push_back(faces[2]);
			
			connections[faces[2]].push_back(faces[0]);
			connections[faces[2]].push_back(faces[1]);
		} 
		
		long *use = new long[verticesNum];
		for(int n=0; n<verticesNum; n++) {
			use[n] = -1;
		}
		
		long depth = -1;
		
		for(int n=0; n<verticesNum; n++) {
			if(use[n]==-1) {
				use[n] = ++depth;
				search(&connections,n,use,depth);
			}
		}
		
		NSLog(@"depth is %ld",depth+1);
		
		float **colors = new float *[depth+1];
		for(int n=0; n<depth+1; n++) {
			colors[n] = new float[3];
			
			if(n==0) {
				colors[n][0] = 0.5;
				colors[n][1] = 0.5;
				colors[n][2] = 0.5;
			}
			else {
				colors[n][0] = (random()%255)/255.0;
				colors[n][1] = (random()%255)/255.0;
				colors[n][2] = (random()%255)/255.0;
			}
		}
		
		NSMutableString *obj = [NSMutableString stringWithString:@""];

		for(int n=0; n<verticesNum; n++) {
			
			if(use[n]==-1) {
				
				[obj appendString:[NSString stringWithFormat:@"v %0.4f %0.4f %04f %0.4f %0.4f %0.4f\n",
					v[n*6+0],
					v[n*6+1],
					v[n*6+2],
					v[n*6+3],
					v[n*6+4],
					v[n*6+5]
				]];
				
			}
			else {
				
				[obj appendString:[NSString stringWithFormat:@"v %0.4f %0.4f %04f %0.4f %0.4f %0.4f\n",
					v[n*6+0],
					v[n*6+1],
					v[n*6+2],
					colors[use[n]][0],
					colors[use[n]][1],
					colors[use[n]][2]
				]];
			}
		} 
		
		for(int n=0; n<facesNum; n++) {
			[obj appendString:[NSString stringWithFormat:@"f %d %d %d\n",
				1+f[n*3+0],
				1+f[n*3+1],
				1+f[n*3+2]
			]];
		} 
		
		[obj writeToFile:@"blobs.obj" atomically:YES encoding:NSUTF8StringEncoding error:nil];

		NSLog(@"%f",CFAbsoluteTimeGetCurrent()-then);
	}
}