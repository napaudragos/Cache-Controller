module cache_controller(
  input clk,rst,
  input read,
  input write,
  input cache_ready,
  input MM_ready,
  input [31:0]address,
  input [63:0]write_data,
  output reg [63:0] read_data,
  output reg hit,
  output reg miss,
  output wire [3:0] state_out
);

  localparam CACHE_SIZE = 32 * 1024;    
  localparam BLOCK_SIZE = 64;            
  localparam SETS = 128;           
  localparam ASSOCIATIVITY = 4;          
	localparam TAG= 19;
	
 
  	
localparam IDLE = 0,
	   TAG_CHECK = 1,
	   VALID = 2,
           READ_HIT = 3,
           WRITE_HIT = 4,
           UPDATE_LRU = 5,
           DONE = 6,
           MISS_SELECT = 7,
           WRITE_BACK = 8,
           ALLOCATE = 9,
           READ_ALLOC = 10,
           WRITE_ALLOC = 11,
           DIRTY_CHECK = 12;
reg [3:0] state_curr;
reg [3:0] state_next;
	
// WAY 1 
  reg VALID1 [0: SETS-1];
  reg [TAG-1:0] TAG1 [0: SETS-1];
  reg [BLOCK_SIZE-1:0] DATA1 [0: SETS-1];
  reg DIRTY1 [0: SETS-1];
  reg [1:0] LRU1 [0: SETS-1];
  
// WAY 2  
  reg VALID2 [0: SETS-1];
  reg [TAG-1:0] TAG2 [0: SETS-1];
  reg [BLOCK_SIZE-1:0] DATA2 [0: SETS-1];
  reg DIRTY2 [0: SETS-1];
  reg [1:0] LRU2 [0: SETS-1];
  
// WAY 3
  reg VALID3 [0: SETS-1];
  reg [TAG-1:0] TAG3 [0: SETS-1];
  reg [BLOCK_SIZE-1:0] DATA3 [0: SETS-1];
  reg DIRTY3 [0: SETS-1];
  reg [1:0] LRU3 [0: SETS-1];
  
// WAY 4 
  reg VALID4 [0: SETS-1];
  reg [TAG-1:0] TAG4 [0: SETS-1];
  reg [BLOCK_SIZE-1:0] DATA4 [0: SETS-1];
  reg DIRTY4 [0: SETS-1];
  reg [1:0] LRU4 [0: SETS-1];
  

  integer v;  
  initial begin
	read_data=0;
  end
  reg [1:0] hit_way;
  reg [1:0] way_used;
  wire [1:0] OffsetWord;
  wire [3:0] OffsetBlock;  
  wire [6:0] index;   
  wire [18:0] tag;    
  reg [3:0] selected_way;
  assign OffsetWord = address[1:0];
  assign OffsetBlock = address[5:2];
  assign index  = address[12:6];
  assign tag    = address[31:13];
  assign state_out = state_curr;
  
  
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // Way 1
        VALID1[0] <= 1'b0; DIRTY1[0] <= 1'b0; TAG1[0] <= 0; DATA1[0] <= 0; LRU1[0] <= 2'b00;
        VALID1[1] <= 1'b0; DIRTY1[1] <= 1'b0; TAG1[1] <= 0; DATA1[1] <= 0; LRU1[1] <= 2'b00;
        VALID1[2] <= 1'b0; DIRTY1[2] <= 1'b0; TAG1[2] <= 0; DATA1[2] <= 0; LRU1[2] <= 2'b00;
        VALID1[3] <= 1'b0; DIRTY1[3] <= 1'b0; TAG1[3] <= 0; DATA1[3] <= 0; LRU1[3] <= 2'b00;

        // Way 2
        VALID2[0] <= 1'b0; DIRTY2[0] <= 1'b0; TAG2[0] <= 0; DATA2[0] <= 0; LRU2[0] <= 2'b00;
        VALID2[1] <= 1'b0; DIRTY2[1] <= 1'b0; TAG2[1] <= 0; DATA2[1] <= 0; LRU2[1] <= 2'b00;
        VALID2[2] <= 1'b0; DIRTY2[2] <= 1'b0; TAG2[2] <= 0; DATA2[2] <= 0; LRU2[2] <= 2'b00;
        VALID2[3] <= 1'b0; DIRTY2[3] <= 1'b0; TAG2[3] <= 0; DATA2[3] <= 0; LRU2[3] <= 2'b00;

        // Way 3
        VALID3[0] <= 1'b0; DIRTY3[0] <= 1'b0; TAG3[0] <= 0; DATA3[0] <= 0; LRU3[0] <= 2'b00;
        VALID3[1] <= 1'b0; DIRTY3[1] <= 1'b0; TAG3[1] <= 0; DATA3[1] <= 0; LRU3[1] <= 2'b00;
        VALID3[2] <= 1'b0; DIRTY3[2] <= 1'b0; TAG3[2] <= 0; DATA3[2] <= 0; LRU3[2] <= 2'b00;
        VALID3[3] <= 1'b0; DIRTY3[3] <= 1'b0; TAG3[3] <= 0; DATA3[3] <= 0; LRU3[3] <= 2'b00;

        // Way 4
        VALID4[0] <= 1'b0; DIRTY4[0] <= 1'b0; TAG4[0] <= 0; DATA4[0] <= 0; LRU4[0] <= 2'b00;
        VALID4[1] <= 1'b0; DIRTY4[1] <= 1'b0; TAG4[1] <= 0; DATA4[1] <= 0; LRU4[1] <= 2'b00;
        VALID4[2] <= 1'b0; DIRTY4[2] <= 1'b0; TAG4[2] <= 0; DATA4[2] <= 0; LRU4[2] <= 2'b00;
        VALID4[3] <= 1'b0; DIRTY4[3] <= 1'b0; TAG4[3] <= 0; DATA4[3] <= 0; LRU4[3] <= 2'b00;
    end
end

  
  always @(posedge clk or posedge rst) begin
        if (rst) begin
          state_curr <= IDLE;    
        end else begin
            state_curr <= state_next;
        end
    end

    always @(*) begin
    case (state_curr)
//-----------------------------------------------------------------------------------------//
        IDLE: begin
            if (read) begin
              state_next = VALID;
            end else if (write) begin
              state_next = VALID;
            end else begin
              state_next = IDLE;
            end
        end
//-----------------------------------------------------------------------------------------//
        VALID: begin
            if((VALID1[index]) || (VALID2[index]) || (VALID3[index]) || (VALID4[index])) begin
              state_next = TAG_CHECK;
            end else begin
              state_next = MISS_SELECT; 
            end
        end
//-----------------------------------------------------------------------------------------//
        TAG_CHECK: begin
          if (VALID1[index] && TAG1[index] == tag) begin
           hit_way = 2'd0;
           state_next = read ? READ_HIT : WRITE_HIT;
          end else if (VALID2[index] && TAG2[index] == tag) begin
            hit_way = 2'd1;
            state_next = read ? READ_HIT : WRITE_HIT;
          end else if (VALID3[index] && TAG3[index] == tag) begin
            hit_way = 2'd2;
            state_next = read ? READ_HIT : WRITE_HIT;
          end else if (VALID4[index] && TAG4[index] == tag) begin
            hit_way = 2'd3;
            state_next = read ? READ_HIT : WRITE_HIT;
          end else begin
            state_next = MISS_SELECT;
          end
        end
//-----------------------------------------------------------------------------------------//
        READ_HIT: begin
          if (hit_way == 0)
              read_data = DATA1[index];
          else if (hit_way == 1)
              read_data = DATA2[index];
          else if (hit_way == 2)
              read_data = DATA3[index];
          else if (hit_way == 3)
              read_data = DATA4[index];

          hit  = 1;
          miss = 0;
          state_next = UPDATE_LRU;
        end
//-----------------------------------------------------------------------------------------//
          WRITE_HIT: begin
            if (hit_way == 0) begin
                DATA1[index] = write_data[63:0];
                DIRTY1[index] = 1;
            end else if (hit_way == 1) begin
                DATA2[index] = write_data[63:0];
                DIRTY2[index] = 1;
            end else if (hit_way == 2) begin
                DATA3[index] = write_data[63:0];
                DIRTY3[index] = 1;
            end else if (hit_way == 3) begin
                DATA4[index] = write_data[63:0];
                DIRTY4[index] = 1;
            end

            hit  = 1;
            miss = 0;
            state_next = UPDATE_LRU;
        end
//-----------------------------------------------------------------------------------------//
        UPDATE_LRU: begin   
            if (state_curr == READ_HIT || state_curr == WRITE_HIT)
                way_used = hit_way;
            else
                way_used = selected_way;

          
            if (way_used == 0) begin
                if (LRU2[index] < LRU1[index]) LRU2[index] = LRU2[index] + 1;
                if (LRU3[index] < LRU1[index]) LRU3[index] = LRU3[index] + 1;
                if (LRU4[index] < LRU1[index]) LRU4[index] = LRU4[index] + 1;
                LRU1[index] = 0;
            end else if (way_used == 1) begin
                if (LRU1[index] < LRU2[index]) LRU1[index] = LRU1[index] + 1;
                if (LRU3[index] < LRU2[index]) LRU3[index] = LRU3[index] + 1;
                if (LRU4[index] < LRU2[index]) LRU4[index] = LRU4[index] + 1;
                LRU2[index] = 0;
            end else if (way_used == 2) begin
                if (LRU1[index] < LRU3[index]) LRU1[index] = LRU1[index] + 1;
                if (LRU2[index] < LRU3[index]) LRU2[index] = LRU2[index] + 1;
                if (LRU4[index] < LRU3[index]) LRU4[index] = LRU4[index] + 1;
                LRU3[index] = 0;
            end else if (way_used == 3) begin
                if (LRU1[index] < LRU4[index]) LRU1[index] = LRU1[index] + 1;
                if (LRU2[index] < LRU4[index]) LRU2[index] = LRU2[index] + 1;
                if (LRU3[index] < LRU4[index]) LRU3[index] = LRU3[index] + 1;
                LRU4[index] = 0;
            end

            state_next = DONE;
        end
//-----------------------------------------------------------------------------------------//
        DONE: begin
            state_next = IDLE;
        end
        MISS_SELECT: begin
            casez ({VALID4[index], VALID3[index], VALID2[index], VALID1[index]})
                4'b???0: selected_way = 4'd0;  // way1 invalid
                4'b??01: selected_way = 4'd1;  // way2 invalid, way1 valid
                4'b?011: selected_way = 4'd2;  // way3 invalid, way1&2 valid
                4'b0111: selected_way = 4'd3;  // way4 invalid, others valid
                4'b1111: begin  
                    if (LRU1[index] == 2'd3) selected_way = 4'd0;
                    else if (LRU2[index] == 2'd3) selected_way = 4'd1;
                    else if (LRU3[index] == 2'd3) selected_way = 4'd2;
                    else selected_way = 4'd3;
                end
                default: selected_way = 4'd0;
            endcase
            state_next = DIRTY_CHECK;
        end
//-----------------------------------------------------------------------------------------//   	
	DIRTY_CHECK: begin
    	if (selected_way == 0) begin
       		if (DIRTY1[index])
            		state_next = WRITE_BACK;
        	else
            		state_next = ALLOCATE;
    	end else if (selected_way == 1) begin
        	if (DIRTY2[index])
            		state_next = WRITE_BACK;
        	else
            		state_next = ALLOCATE;
    	end else if (selected_way == 2) begin
        	if (DIRTY3[index])
           		state_next = WRITE_BACK;
        	else
            		state_next = ALLOCATE;
    	end else if (selected_way == 3) begin
        	if (DIRTY4[index])
            		state_next = WRITE_BACK;
       		else
            		state_next = ALLOCATE;
    	end else begin
        	state_next = ALLOCATE;
    end
end

//-----------------------------------------------------------------------------------------//
        WRITE_BACK: begin
         case (selected_way)
           0: begin
            DIRTY1[index] = 0;
            state_next = ALLOCATE;
           end
           1: begin
            DIRTY2[index] = 0;
            state_next = ALLOCATE;
           end
           2: begin
            DIRTY3[index] = 0;
            state_next = ALLOCATE;
           end
           3: begin
            DIRTY4[index] = 0;
            state_next = ALLOCATE;
           end
           endcase
          end
//-----------------------------------------------------------------------------------------//
        ALLOCATE: begin
          case (selected_way)
            0: begin
            TAG1[index]   <= tag;
            VALID1[index] <= 1;
            DIRTY1[index] <= 0;
            DATA1[index]  <= 64'hDEADBEEFCAFEBABE;
          end
            1: begin
            TAG2[index]   <= tag;
            VALID2[index] <= 1;
            DIRTY2[index] <= 0;
            DATA2[index]  <= 64'hDEADBEEFCAFEBABE;
          end
            2: begin
            TAG3[index]   <= tag;
            VALID3[index] <= 1;
            DIRTY3[index] <= 0;
            DATA3[index]  <= 64'hDEADBEEFCAFEBABE;
          end
            3: begin
            TAG4[index]   <= tag;
            VALID4[index] <= 1;
            DIRTY4[index] <= 0;
            DATA4[index]  <= 64'hDEADBEEFCAFEBABE;
          end
        endcase
        if (read)
          state_next = READ_ALLOC;
        else if (write)
          state_next = WRITE_ALLOC;
        else
          state_next = DONE;
        end
//-----------------------------------------------------------------------------------------//
        READ_ALLOC: begin
            case (selected_way)
              0: read_data = DATA1[index];
              1: read_data = DATA2[index];
              2: read_data = DATA3[index];
              3: read_data = DATA4[index];
            endcase
            hit  = 0;
            miss = 1;
            state_next = UPDATE_LRU;
        end
//-----------------------------------------------------------------------------------------//
        WRITE_ALLOC: begin
          case (selected_way)
            0: begin
               DATA1[index] = write_data[63:0];
              DIRTY1[index] = 1;
            end
            1: begin
               DATA2[index] = write_data[63:0];
              DIRTY2[index] = 1;
            end
            2: begin
               DATA3[index] = write_data[63:0];
              DIRTY3[index] = 1;
            end
            3: begin
               DATA4[index] = write_data[63:0];
              DIRTY4[index] = 1;
            end
          endcase
          hit  = 0;
          miss = 1;
          state_next = UPDATE_LRU;
        end
//-----------------------------------------------------------------------------------------//
        default: state_next = IDLE;
    endcase
end
endmodule
