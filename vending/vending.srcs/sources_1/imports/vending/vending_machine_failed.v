// Title         : vending_machine.v
// Author      : Hunjun Lee (hunjunlee7515@snu.ac.kr), Suheon Bae (suheon.bae@snu.ac.kr)

`include "vending_machine_def.v"

module vending_machine (

	clk,							// Clock signal
	reset_n,						// Reset signal (active-low)

	i_input_coin,				// coin is inserted.
	i_select_item,				// item is selected.
	i_trigger_return,			// change-return is triggered

	o_available_item,			// Sign of the item availability
	o_output_item,			   // Sign of the item withdrawal
	o_return_coin,			   // Sign of the coin return
	o_current_total
);

	// Ports Declaration
	input clk;
	input reset_n;

	input [`kNumCoins-1:0] i_input_coin;
	input [`kNumItems-1:0] i_select_item;
	input i_trigger_return;

	output reg [`kNumItems-1:0] o_available_item;
	output reg [`kNumItems-1:0] o_output_item;
	output reg [`kReturnCoins-1:0] o_return_coin;
	output reg [`kTotalBits-1:0] o_current_total;

	// Net constant values (prefix kk & CamelCase)
	wire [31:0] kkItemPrice [`kNumItems-1:0];	// Price of each item
	wire [31:0] kkCoinValue [`kNumCoins-1:0];	// Value of each coin
	assign kkItemPrice[0] = 400;
	assign kkItemPrice[1] = 500;
	assign kkItemPrice[2] = 1000;
	assign kkItemPrice[3] = 2000;
	assign kkCoinValue[0] = 100;
	assign kkCoinValue[1] = 500;
	assign kkCoinValue[2] = 1000;

	// Internal states. You may add your own reg variables.
	reg [`kTotalBits-1:0] current_total;
	reg [`kItemBits-1:0] num_items [`kNumItems-1:0]; //use if needed
	reg [`kCoinBits-1:0] num_coins [`kNumCoins-1:0]; //use if needed

	// my var
	reg [`kTotalBits-1:0] inserted_coins;
	reg [`kTotalBits-1:0] next_inserted;
	reg [`kNumItems-1:0] user_sel;
	reg [`kNumItems-1:0] next_sel;

	// init
	initial begin
		inserted_coins <= 0;
		user_sel <= 0;
	end

	// Combinational circuit for the next states
	always @(*) begin
		// if coin is inserted
		if (i_input_coin != 0) begin
			case (i_input_coin) 
				3'b001 : next_inserted = inserted_coins + kkCoinValue[0];
				3'b010 : next_inserted = inserted_coins + kkCoinValue[1];
				3'b100 : next_inserted = inserted_coins	+ kkCoinValue[2];
			endcase
		end
		// if item is selected
		else if (i_select_item != 0) begin
			next_sel = i_select_item;
			case (i_select_item) 
				4'b0001 : next_inserted = inserted_coins - kkItemPrice[0];
				4'b0010 : next_inserted = inserted_coins - kkItemPrice[1];
				4'b0100 : next_inserted = inserted_coins - kkItemPrice[2];
				4'b1000 : next_inserted = inserted_coins - kkItemPrice[3];
			endcase
		end
		else if (i_trigger_return == 1) begin
			next_inserted = 0;
		end
		else begin
			next_inserted = inserted_coins;
			next_sel = user_sel;
		end
	end

	// Combinational circuit for the output
	always @(*) begin
		// temp .. if I implement extra..then have to change it
		if (inserted_coins >= kkItemPrice[3]) o_available_item = 4'b1111;
		else if (inserted_coins >= kkItemPrice[2]) o_available_item = 4'b0111;
		else if (inserted_coins >= kkItemPrice[1]) o_available_item = 4'b0011;
		else if (inserted_coins >= kkItemPrice[0]) o_available_item = 4'b0001;
		else o_available_item = 4'b0000; 

		// if item is sufficient and price is less than total coin, then output is selected
		case (user_sel)
			4'b0000 : o_output_item = 0;
			4'b0001 : begin
				if (inserted_coins / kkItemPrice[0] != 0) o_output_item = user_sel;
				else o_output_item = 0;
			end
			4'b0010 : begin
				if (inserted_coins / kkItemPrice[1] != 0) o_output_item = user_sel;
				else o_output_item = 0;
			end
			4'b0100 : begin
				if (inserted_coins / kkItemPrice[2] != 0) o_output_item = user_sel;
				else o_output_item = 0;
			end
			4'b1000 : begin
				if (inserted_coins / kkItemPrice[3] != 0) o_output_item = user_sel;
				else o_output_item = 0;
			end
		endcase

		o_current_total = inserted_coins;

		//return tot coin num if trigger == 0
		if (i_trigger_return == 1) begin
			o_return_coin = (inserted_coins / kkCoinValue[2]) + (inserted_coins % kkCoinValue[2]) / kkCoinValue[1] + (inserted_coins % kkCoinValue[2] % kkCoinValue[1]) / kkCoinValue[0];
		end
		else o_return_coin = 0;
	end

	// Sequential circuit to reset or update the states
	always @(posedge clk) begin
		if (!reset_n) begin
			// TODO: reset all states.
			inserted_coins <= 0;
		end
		else begin
			// TODO: update all states.
			inserted_coins <= next_inserted;
			user_sel <= next_sel;
		end
	end

endmodule
