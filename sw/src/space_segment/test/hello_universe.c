#include <stdio.h>
#include <or1k-support.h>

//Config constants
const int default_rx_value = 1073741826;
const int sleep_count = 20000000;
const unsigned int tx_rand_seed = 0;

//WB slaves addresses
char* leds_gpio0_addr = (char*) 0x91000000;
int* ccsds_rxtx0_rxtx_addr = (int*) 0xc0000000;

//  char* ccsds_rxtx0_rxtx_addr = (char*) 0xc0000000;
//int* ccsds_rxtx0_rx_conf_addr = (int*) 0xc0000001;
//int* ccsds_rxtx0_tx_conf_addr = (int*) 0xc0000002;


int init_random(unsigned int seed)
{
  srand (seed);
  return 0;
}

int sleep(int cycle_num)
{
  int count = 0;
  while (count < cycle_num)
  {
    count++;
  }
  return 0;
}

int visual_control_seq(int type)
{
  //set to write IO
  *(leds_gpio0_addr+1) = 0xff;
  switch (type)
  {
    //init sequence
    case 0:
      //ON
      *(leds_gpio0_addr+0) = 0xff;
      sleep(sleep_count/4);
      //OFF
      *(leds_gpio0_addr+0) = 0x00;
      sleep(sleep_count/4);
      //ON
      *(leds_gpio0_addr+0) = 0xff;
      sleep(sleep_count/4);
      //OFF
      *(leds_gpio0_addr+0) = 0x00;
      sleep(sleep_count/4);
      //ON
      *(leds_gpio0_addr+0) = 0xff;
      break;
    //stop sequence
    case 1:
      //OFF
      *(leds_gpio0_addr+0) = 0x00;
      sleep(sleep_count/4);
      //ON
      *(leds_gpio0_addr+0) = 0xff;
      sleep(sleep_count/4);
      //OFF
      *(leds_gpio0_addr+0) = 0x00;
      sleep(sleep_count/4);
      //ON
      *(leds_gpio0_addr+0) = 0xff;
      sleep(sleep_count/4);
      //OFF
      *(leds_gpio0_addr+0) = 0x00;
      break;
    default:
      //ON
      *(leds_gpio0_addr+0) = 0xff;
      return 1;
  }
  return 0;
}

int receive_data(int type)
{
  int rx_data;
  rx_data = *(ccsds_rxtx0_rxtx_addr);
  switch (type)
  {
    //default value
    case 0:
      if (rx_data == default_rx_value)
      {
        printf("OK: default value detected\n");
      }
      else
      {
        printf("KO: not default value detected\n");
        printf("DEBUG: RX data: %u\n", rx_data);
        return 1;
      }
      break;
    default:
      return 1;
  }
  return 0;
}


int send_data(int type)
{
  int tx_data;
  switch (type)
  {
    //all 0 datagram
    case 0:
      tx_data = 0x00000000;
      break;
    //all 1 datagram
    case 1:
      tx_data = 0xffffffff;
      break;
    //random datagram
    case 2:
      tx_data = rand();
      break;
    default:
      return 1;
  }
  *(ccsds_rxtx0_rxtx_addr) = tx_data;
  return 0;
}

int main(void)
{
  unsigned int loop_counter = 0;
  
  printf("_______________________________________\n\n");
  printf("OpenRISC EurySPACE Space Segment test program started\n");
  printf("_______________________________________\n\n");

  printf("START: visual control sequence - init sequence\n");
  if (visual_control_seq(0) == 0)
  {
    printf("OK: visual control sequence - init sequence\n");
  }
  else
  {
    printf("KO: visual control sequence - error - init sequence\n");
  }
  printf("DONE: visual control sequence - init sequence\n");

  printf("START: RX/TX control sequence - default init parameters\n");
  if (receive_data(0) == 0)
  {
    printf("OK: RX/TX control sequence - default init parameters\n");
  }
  else
  {
    printf("KO: RX/TX control sequence - error - default init parameters\n");
  }
  printf("DONE: RX/TX control sequence - default init parameters\n");

  printf("START: RX/TX control sequence - tx data transmission\n");
  if (send_data(0) == 0)
  {
    printf("OK: RX/TX control sequence - time domain analysis - tx data changed to all 0\n");
    printf("CHECK: RX/TX control sequence - time domain analysis - TX data are all 0 - inspect signal level\n");
    sleep(sleep_count);
  }
  else
  {
    printf("KO: RX/TX control sequence - time domain analysis - error - tx data not changed to all 0\n");
  }
  
  if (send_data(1) == 0)
  {
    printf("OK: RX/TX control sequence - time domain analysis - tx data changed to all 1\n");
    printf("CHECK: RX/TX control sequence - time domain analysis - TX data are all 1 - inspect signal level\n");
    sleep(sleep_count);
  }
  else
  {
    printf("KO: RX/TX control sequence - time domain analysis - error - tx data not changed to all 1\n");
  }

  printf("CHECK: RX/TX control sequence - frequency domain analysis - changing TX data alternation - inspect signal spectrum\n");
  loop_counter = 0;
  while (send_data(0) == 0 && send_data(1) == 0 && loop_counter < 10000000)
  {
    loop_counter++;
  //  sleep(1);
  }


  printf("CHECK: RX/TX control sequence - frequency domain analysis - changing TX data randomly - inspect signal spectrum\n");
  init_random(tx_rand_seed);
  while (send_data(2) == 0)
  {
  //  sleep(1);
  }


//  sleep(sleep_count);
//  printf("Bad RX read: %h\n", *(ccsds_rxtx0_rxtx_addr+1));

//  sleep(sleep_count);
//  printf("Stopping RX\n");
//  *(ccsds_rxtx0_rx_conf_addr) = 0x00000000;

//  sleep(sleep_count);
//  printf("Stopping TX\n");
//  *(ccsds_rxtx0_tx_conf_addr) = 0x00;
  
//  sleep(sleep_count);
//  printf("Starting RX\n");
//  *(ccsds_rxtx0_rx_conf_addr) = 0xffffffff;

//  sleep(sleep_count);
//  printf("Starting TX\n");
//  *(ccsds_rxtx0_tx_conf_addr) = 0xff;
  
/*  sleep(sleep_count);
  printf("Changing TX configuration to internal\n");
  *(ccsds_rxtx0_addr+2) = 0x01;
  // wait some time
  sleep(sleep_count);
  printf("Changing RX configuration to internal\n");
  *(ccsds_rxtx0_addr+1) = 0x01;
*/


  
//  *(ccsds_rxtx0_tx_conf_addr) = 0x11111111;
//  *(ccsds_rxtx0_rxtx_addr+1) = 0x00000000;
//  *(ccsds_rxtx0_rxtx_addr+1) = 0x00000000;

//  *(ccsds_rxtx0_rxtx_addr+0) = 0x00;
//  *(ccsds_rxtx0_rxtx_addr+1) = 0x00;
//  *(ccsds_rxtx0_rxtx_addr+2) = 0x00;
//  *(ccsds_rxtx0_rxtx_addr+3) = 0x00;
//  *(ccsds_rxtx0_rxtx_addr+4) = 0x00;
//  *(ccsds_rxtx0_rxtx_addr+5) = 0x00;
//  *(ccsds_rxtx0_rxtx_addr+6) = 0x00;
//  *(ccsds_rxtx0_rxtx_addr+7) = 0x00;
/*  sleep(sleep_count);
  printf("Starting TX\n");
  *(ccsds_rxtx0_tx_conf_addr) = 0xffffffff;
  *(ccsds_rxtx0_rx_conf_addr) = 0xffffffff;
  *(ccsds_rxtx0_rxtx_addr) = 0xffffffff;
*/
  
/*  // wait some time
  sleep(sleep_count);
  printf("Stopping RX\n");
  *(ccsds_rxtx0_addr+1) = 0x01;
  // wait some time
*/


  printf("START: visual control sequence - stop sequence\n");
  visual_control_seq(1);
  printf("END: visual control sequence - stop sequence\n");
  printf("_______________________________________\n\n");
  printf("OpenRISC EurySPACE Space Segment test program stopped\n");
  return 0;
}
