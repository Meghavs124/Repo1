`timescale 1ns / 1ps
module FOUR_bit_ALU_rtl_design #(parameter N=4)(OPA,OPB,INP_VALID,CIN,CLK,RST,CMD,CE,MODE,COUT,OFLOW,RES,G,E,L,ERR);
 
  input [N-1:0] OPA,OPB;
  input CLK,RST,CE,MODE,CIN;
  input [N-1:0] CMD;
  input [1:0]INP_VALID;
  output reg [(2*N)-1:0] RES = 8'b0;
  output reg COUT = 1'b0;
  output reg OFLOW = 1'b0;
  output reg G = 1'b0;
  output reg E = 1'b0;
  output reg L = 1'b0;
  output reg ERR = 1'b0;
 
 reg [N+1:0]temp1;
 
reg [1:0] count;
 
 reg [N-1:0] rot_temp;
 
 integer shift;
 
    always@(posedge CLK or posedge RST)
      begin
         if(RST)               
          begin
            RES=8'b00000000;
            COUT=1'b0;
            OFLOW=1'b0;
            G=1'b0;
            E=1'b0;
            L=1'b0;
            ERR=1'b0;
            count=1'b0;
          end
      else if(CE)
       begin
          if(MODE)        
         begin
           RES=8'b00000000;
           COUT=1'b0;
           OFLOW=1'b0;
           G=1'b0;
           E=1'b0;
           L=1'b0;
           ERR=1'b0;
           
          case(CMD) 
          //CMD 0 unsigned add            
           4'b0000:             
            begin  
            if(INP_VALID==2'b11)
             begin           
              RES=OPA+OPB;
              COUT=RES[N]?1:0;
             end 
            else
            ERR=1'b1;
            end
            
               //CMD 1 unsigned sub
	      4'b0001:             
            begin
             if(INP_VALID==2'b11)
             begin
              OFLOW=(OPA<OPB)?1:0;
              RES=OPA-OPB;
             end
             else
               ERR=1'b1;
            end 
            
               //CMD 2 add with cin
           4'b0010:             
            begin
            if(INP_VALID==2'b11)
            begin
             RES=OPA+OPB+CIN;
             COUT=RES[N]?1:0;
            end
            else
             ERR=1'b1;
            end
            
            //CMD 3 sub with cin
           4'b0011:             
           begin
             if(INP_VALID==2'b11)
              begin
               OFLOW=(OPA<OPB)?1:0;
               RES=OPA-OPB-CIN;
              end
             else
              ERR=1'b1;
           end
           
           //CMD 4 increment_A
           4'b0100:
           begin
            if(INP_VALID==2'b01 || INP_VALID==2'b11)
             RES=OPA+1;  
            else
             ERR=1'b1;
           end 
                
          //cmd 5 decrement A      
           4'b0101:
           begin   
            if(INP_VALID==2'b01 || INP_VALID==2'b11)
             RES=OPA-1; 
            else
             ERR=1'b1;
           end 
           
           //cmd 6 increment B
           4'b0110: 
           begin
            if(INP_VALID==2'b10 || INP_VALID==2'b11)
                RES=OPB+1; 
            else
              ERR=1'b1;
           end 
           
           //cmd 7 decrement B
           4'b0111:
           begin
            if(INP_VALID==2'b10 || INP_VALID==2'b11)
                RES=OPB-1;
            else
              ERR=1'b1;
           end 
           
           //cmd 8 cmpare   
           4'b1000:              
           begin
            RES=8'b00000000;
           if(INP_VALID==2'b11)
            begin
             if(OPA==OPB)
              begin
               E=1'b1;
               G=1'b0;
               L=1'b0;
              end
             else if(OPA>OPB)
              begin
               E=1'b0;
               G=1'b1;
               L=1'b0;
              end
             else 
              begin
               E=1'b0;
               G=1'b0;
               L=1'b1;
              end
            end
           else
            ERR=1'b1;
           end
           
           //cmd 9 mul res at  3rd clk cycle
           
           4'b1001:
           begin
           if(INP_VALID==2'b11)
           begin
           if (count == 0) 
		   begin
            temp1 = 0;
             count = 1;
            end
          else if(count==1)
           begin
           temp1=(OPA+1)*(OPB+1);
           count=count+1;
           end
          // for(count=1;count<=3;count=count+1)
           else if(count==2)
           begin
           RES = temp1;
           count=0;
           end
           end
           else
           ERR=1'b1;
           end
           
           //cmd 10 shift and mul
           4'b1010:
           begin
           if(INP_VALID==2'b11)
           begin
           if (count == 2'd0) 
		   begin
             temp1 = 0;
             count = 1;
           end
           else if(count==1) 
		   begin
           temp1=(OPA<<1)*OPB;
           count=count+1;
           end
          // for(count=1;count<=3;count=count+1)
           else if(count==2)
		   begin
           RES=temp1;
           count=0;
           end
           end
           else
           ERR=1'b1;
           end
           
           //cmd 11signed addition and comparision
           4'b1011:
           begin
            if(INP_VALID==2'b11)
             begin
              RES=$signed(OPA) + $signed(OPB);
              //COUT=RES[8]?1:0;
              OFLOW=(OPA[N-1]==OPB[N-1]&& RES[N-1]!=OPA[N-1]);
             end 
             if (INP_VALID==2'b11) 
             begin
                if($signed(OPA)==$signed(OPB))
                  begin
                      E=1'b1;
                      G=1'b0;
                      L=1'b0;
                  end 
                else if($signed(OPA)>$signed(OPB))
                   begin
                     E=1'b0;
                     G=1'b1;
                     L=1'b0;
                  end
                else 
                   begin
                    E=1'b0;
                    G=1'b0;
                    L=1'b1;
                   end
             end        
            else
               ERR=1'b1;
            end 
            
            //cmd 12 signed sub and compare
             4'b1100:
           begin
            if(INP_VALID==2'b11)
             begin
              RES=$signed(OPA) - $signed(OPB);
              //COUT=RES[8]?1:0;
              OFLOW=(OPA[N-1]!=OPB[N-1]&& RES[N-1]!=OPA[N-1]);
              end 
             if (INP_VALID==2'b11) 
             begin
                if($signed(OPA)==$signed(OPB))
                  begin
                      E=1'b1;
                      G=1'b0;
                      L=1'b0;
                  end
                else if($signed(OPA)>$signed(OPB))
                   begin
                     E=1'b0;
                     G=1'b1;
                     L=1'b0;
                  end
                else 
                   begin
                    E=1'b0;
                    G=1'b0;
                    L=1'b1;
                   end
             end        
            else
               ERR=1'b1;
            end 
            
           
           default:
            begin
            RES=8'b00000000;
            COUT=1'b0;
            OFLOW=1'b0;
            G=1'b0;
            E=1'b0;
            L=1'b0;
            ERR=1'b0;
           end
          endcase
         end
 
        else          
        begin 
           RES=8'b00000000;
           COUT=1'b00;
           OFLOW=1'b0;
           G=1'b0;
           E=1'b0;
           L=1'b0;
           ERR=1'b0;
           
         case(INP_VALID)
         2'b00: ERR=1'b1;
         
         2'b01: begin
         case(CMD)
         4'b0110:RES={1'b0,~OPA}; 
         4'b1000:RES={1'b0,OPA>>1};      
         4'b1001:RES={1'b0,OPA<<1}; 
         default : ERR=1'b1;
         endcase 
         end
         
         2'b10: begin
         case(CMD)
         4'b0111:RES={1'b0,~OPB};
         4'b1010:RES={1'b0,OPB>>1};      
         4'b1011:RES={1'b0,OPB<<1};  
         default : ERR=1'b1;
         endcase
         end
         
         2'b11: begin
         case(CMD)
         4'b0000:RES={1'b0,OPA&OPB};     
         4'b0001:RES={1'b0,~(OPA&OPB)};  
         4'b0010:RES={1'b0,OPA|OPB};     
         4'b0011:RES={1'b0,~(OPA|OPB)}; 
         4'b0100:RES={1'b0,OPA^OPB}; 
         4'b0101:RES={1'b0,~(OPA^OPB)};
         4'b1100:                        
             begin             
              if(OPB[N-1:3]!=0)
              ERR=1'b1;
             else
              begin
               shift = OPB % N;   
               rot_temp = (OPA << shift) | (OPA >> (N - shift));
               RES = rot_temp;
             end 
             end
         4'b1101: 
         begin
         if(OPB[N-1:3]!=0)
         ERR=1'b1;
         else
         begin
          shift = OPB % N;
          rot_temp = (OPA >> shift) | (OPA << (N - shift));
          RES = rot_temp;
         end
        end
             
        default:    
               begin
               RES=8'b00000000;
               COUT=1'b0;
               OFLOW=1'b0;
               G=1'b0;
               E=1'b0;
               L=1'b0;
               ERR=1'b0;
               end
          endcase
     end
   endcase
   end
  
   end
 end
 endmodule  
  
