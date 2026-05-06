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


reg [N-1:0] r_OPA, r_OPB;
reg r_CIN, r_MODE;
reg [N-1:0] r_CMD;
reg [1:0] r_INP_VALID;

always@(posedge CLK or posedge RST)
  begin
    if(RST)
      begin
        r_OPA<=0; r_OPB<=0; r_CIN<=0;
        r_MODE<=0; r_CMD<=0; r_INP_VALID<=0;
      end
    else if(CE)
      begin
        r_OPA       <= OPA;        
        r_OPB       <= OPB;
        r_CIN       <= CIN;
        r_MODE      <= MODE;
        r_CMD       <= CMD;
        r_INP_VALID <= INP_VALID;
      end
  end


    always@(posedge CLK or posedge RST)
      begin
         if(RST)               
          begin
            RES<=8'b00000000;
            COUT<=1'b0;
            OFLOW<=1'b0;
            G<=1'b0;
            E<=1'b0;
            L<=1'b0;
            ERR<=1'b0;
            count<=1'b0;
          end
      else if(CE)
       begin
          if(r_MODE)        
         begin
           RES<=8'b00000000;
           COUT<=1'b0;
           OFLOW<=1'b0;
           G<=1'b0;
           E<=1'b0;
           L<=1'b0;
           ERR<=1'b0;
           
          case(r_CMD) 
         
           4'b0000:             
            begin  
            if(r_INP_VALID==2'b11)
             begin           
              RES<=r_OPA+r_OPB;
              COUT<=RES[N]?1:0;
             end 
            else
            ERR<=1'b1;
            end
            
            
	      4'b0001:             
            begin
             if(r_INP_VALID==2'b11)
             begin
              OFLOW<=(r_OPA<r_OPB)?1:0;
              RES<=r_OPA-r_OPB;
             end
             else
               ERR<=1'b1;
            end 
            
           
           4'b0010:             
            begin
            if(r_INP_VALID==2'b11)
            begin
             RES<=r_OPA+r_OPB+r_CIN;
             COUT<=RES[N]?1:0;
            end
            else
             ERR<=1'b1;
            end
            
            
           4'b0011:             
           begin
             if(r_INP_VALID==2'b11)
              begin
               OFLOW<=(r_OPA<r_OPB)?1:0;
               RES<=r_OPA-r_OPB-r_CIN;
              end
             else
              ERR<=1'b1;
           end
           
          
           4'b0100:
           begin
            if(r_INP_VALID==2'b01 || r_INP_VALID==2'b11)
             RES<=r_OPA+1;  
            else
             ERR<=1'b1;
           end 
                
          
           4'b0101:
           begin   
            if(r_INP_VALID==2'b01 || r_INP_VALID==2'b11)
             RES<=r_OPA-1; 
            else
             ERR<=1'b1;
           end 
           
          
           4'b0110: 
           begin
            if(r_INP_VALID==2'b10 || r_INP_VALID==2'b11)
                RES<=r_OPB+1; 
            else
              ERR<=1'b1;
           end 
           
           
           4'b0111:
           begin
            if(r_INP_VALID==2'b10 || r_INP_VALID==2'b11)
                RES<=r_OPB-1;
            else
              ERR<=1'b1;
           end 
           
           
           4'b1000:              
           begin
            RES<=8'b00000000;
           if(r_INP_VALID==2'b11)
            begin
             if(r_OPA==r_OPB)
              begin
               E<=1'b1;
               G<=1'b0;
               L<=1'b0;
              end
             else if(r_OPA>r_OPB)
              begin
               E<=1'b0;
               G<=1'b1;
               L<=1'b0;
              end
             else 
              begin
               E<=1'b0;
               G<=1'b0;
               L<=1'b1;
              end
            end
           else
            ERR<=1'b1;
           end
           
          
           
           4'b1001:                   
           begin
           if(INP_VALID==2'b11)
           begin
           if (count == 0) 
		   begin
            temp1 =(OPA+1)*(OPB+1);
             count <= 1;
            end
          /*else if(count==1)
           begin
           temp1<=(OPA+1)*(OPB+1);
           count<=count+1;
           end
        */
           else if(count==1)
           begin
           RES <= temp1;
           count<=0;
           end
           end
           
           else
           ERR<=1'b1;
           end
           
           
           4'b1010:                   
           begin
           if(INP_VALID==2'b11)
           begin
           if (count == 2'd0) 
		   begin
             temp1 = (OPA<<1)*OPB;
             count <= 1;
           end
          /* else if(count==1) 
		   begin
           temp1<=(OPA<<1)*OPB;
           count<=count+1;
           end
          */
             else if(count==1)
		   begin
           RES<=temp1;
           count<=0;
           end
           end
           else
           ERR<=1'b1;
           end
           
           
           4'b1011:
           begin
            if(r_INP_VALID==2'b11)
             begin
              RES<=$signed(r_OPA) + $signed(r_OPB);
              
              OFLOW<=(r_OPA[N-1]==r_OPB[N-1]&& RES[N-1]!=r_OPA[N-1]);
             end 
             if (r_INP_VALID==2'b11) 
             begin
                if($signed(r_OPA)==$signed(r_OPB))
                  begin
                      E<=1'b1;
                      G<=1'b0;
                      L<=1'b0;
                  end 
                else if($signed(r_OPA)>$signed(r_OPB))
                   begin
                     E<=1'b0;
                     G<=1'b1;
                     L<=1'b0;
                  end
                else 
                   begin
                    E<=1'b0;
                    G<=1'b0;
                    L<=1'b1;
                   end
             end        
            else
               ERR<=1'b1;
            end 
            
            
             4'b1100:
           begin
            if(r_INP_VALID==2'b11)
             begin
              RES<=$signed(r_OPA) - $signed(r_OPB);
              
              OFLOW<=(r_OPA[N-1]!=r_OPB[N-1]&& RES[N-1]!=r_OPA[N-1]);
              end 
             if (r_INP_VALID==2'b11) 
             begin
                if($signed(r_OPA)==$signed(r_OPB))
                  begin
                      E<=1'b1;
                      G<=1'b0;
                      L<=1'b0;
                  end
                else if($signed(r_OPA)>$signed(r_OPB))
                   begin
                     E<=1'b0;
                     G<=1'b1;
                     L<=1'b0;
                  end
                else 
                   begin
                    E<=1'b0;
                    G<=1'b0;
                    L<=1'b1;
                   end
             end        
            else
               ERR<=1'b1;
            end 
            
           
           default:
            begin
            RES<=8'b00000000;
            COUT<=1'b0;
            OFLOW<=1'b0;
            G<=1'b0;
            E<=1'b0;
            L<=1'b0;
            ERR<=1'b0;
           end
          endcase
         end
 
        else          
        begin 
           RES<=8'b00000000;
           COUT<=1'b00;
           OFLOW<=1'b0;
           G<=1'b0;
           E<=1'b0;
           L<=1'b0;
           ERR<=1'b0;
           
         case(r_INP_VALID)
         2'b00: ERR<=1'b1;
         
         2'b01: begin
         case(r_CMD)
         4'b0110:RES<={1'b0,~r_OPA}; 
         4'b1000:RES<={1'b0,r_OPA>>1};      
         4'b1001:RES<={1'b0,r_OPA<<1}; 
         default : ERR<=1'b1;
         endcase 
         end
         
         2'b10: begin
         case(r_CMD)
         4'b0111:RES<={1'b0,~r_OPB};
         4'b1010:RES<={1'b0,r_OPB>>1};      
         4'b1011:RES<={1'b0,r_OPB<<1};  
         default : ERR<=1'b1;
         endcase
         end
         
         2'b11: begin
         case(r_CMD)
         4'b0000:RES<={1'b0,r_OPA&r_OPB};     
         4'b0001:RES<={1'b0,~(r_OPA&r_OPB)};  
         4'b0010:RES<={1'b0,r_OPA|r_OPB};     
         4'b0011:RES<={1'b0,~(r_OPA|r_OPB)}; 
         4'b0100:RES<={1'b0,r_OPA^r_OPB}; 
         4'b0101:RES<={1'b0,~(r_OPA^r_OPB)};
         4'b1100:                        
             begin             
              if(r_OPB[N-1:3]!=0)
              ERR<=1'b1;
             else
              begin
               shift = r_OPB % N;   
               rot_temp = (r_OPA << shift) | (r_OPA >> (N - shift));
               RES <= rot_temp;
             end 
             end
         4'b1101: 
         begin
         if(r_OPB[N-1:3]!=0)
         ERR<=1'b1;
         else
         begin
          shift = r_OPB % N;
          rot_temp = (r_OPA >> shift) | (r_OPA << (N - shift));
          RES <= rot_temp;
         end
        end
             
        default:    
               begin
               RES<=8'b00000000;
               COUT<=1'b0;
               OFLOW<=1'b0;
               G<=1'b0;
               E<=1'b0;
               L<=1'b0;
               ERR<=1'b0;
               end
          endcase
     end
   endcase
   end
   end
        
 end
 endmodule
