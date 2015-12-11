#include <nrf.h>
#include <stdint.h>
#include <stdbool.h>

#define PWM_PIN_0 (22UL)
#define PWM_PIN_1 (23UL)
#define PWM_PIN_2 (24UL)
#define BUTTON1_PIN (13UL)
#define BUTTON2_PIN (14UL)
#define BUTTON3_PIN (15UL)
#define BUTTON4_PIN (16UL)


#define SERVO_MAX ((1UL << 15) | 1900)
#define SERVO_MIN ((1UL << 15) | 1100)
#define SERVO_MID ((1UL << 15) | 1500)

uint32_t m_buf32[2];
uint16_t* m_buf;

uint16_t m_pitch = 500;
uint16_t m_yaw = 500;
uint16_t m_roll = 500;

#define RUDDER (2)
#define LEFT_FLAPS (1)
#define RIGHT_FLAPS (0)

void ASSERT(void)
{
  while (1);
}

bool pitch(uint16_t value)
{
  if (value < 1000)
  {
    m_pitch = value;

    return true;
  }
  return false;
}

bool roll(uint16_t value)
{
  if (value < 1000)
  {
    m_roll = value;

    return true;
  }
  return false;
}

bool yaw(uint16_t value)
{
  if (value < 1000)
  {
    m_yaw = value;
    return true;
  }
  return false;
}

void update_servos()
{
  uint16_t left_flap, right_flap;
  m_buf[RUDDER] = (1UL << 15) | (1000UL + m_yaw);


  left_flap = (1UL << 15) | (((m_roll + m_pitch) / 2) + 1000);
  right_flap = (1UL << 15) | (((m_roll + (1000 - m_pitch)) / 2) + 1000);
  //m_buf[LEFT_FLAPS] = m_buf[RIGHT_FLAPS] = (1UL << 15) | (1000 + m_roll);
  //m_buf[LEFT_FLAPS] = (1UL << 15) | (1000 + m_roll);
  //m_buf[RIGHT_FLAPS] = (1UL << 15) | (1000 + (1000 - m_roll));

  m_buf[LEFT_FLAPS] = left_flap;
  m_buf[RIGHT_FLAPS] = right_flap;

}

int main(void)
{
  uint32_t tmo;

  NRF_CLOCK->TASKS_HFCLKSTART = 1;
  while (NRF_CLOCK->EVENTS_HFCLKSTARTED == 0);
  NRF_CLOCK->EVENTS_HFCLKSTARTED = 0;

  m_buf = (uint16_t*)&m_buf32[0];
  for(int i=0;i<4;i++)
      m_buf[i] = SERVO_MID;

  NRF_GPIO->DIRSET = (1 << PWM_PIN_0) | (1 << PWM_PIN_1) | (1 << PWM_PIN_2);
  NRF_GPIO->OUTCLR = (1 << PWM_PIN_0) | (1 << PWM_PIN_1) | (1 << PWM_PIN_2);

  NRF_GPIO->PIN_CNF[BUTTON1_PIN] = (GPIO_PIN_CNF_DIR_Input << GPIO_PIN_CNF_DIR_Pos) |
                                   (GPIO_PIN_CNF_PULL_Pullup << GPIO_PIN_CNF_PULL_Pos) |
                                   (GPIO_PIN_CNF_INPUT_Connect << GPIO_PIN_CNF_INPUT_Pos);
  NRF_GPIO->PIN_CNF[BUTTON2_PIN] = (GPIO_PIN_CNF_DIR_Input << GPIO_PIN_CNF_DIR_Pos) |
                                   (GPIO_PIN_CNF_PULL_Pullup << GPIO_PIN_CNF_PULL_Pos) |
                                   (GPIO_PIN_CNF_INPUT_Connect << GPIO_PIN_CNF_INPUT_Pos);
  NRF_GPIO->PIN_CNF[BUTTON3_PIN] = (GPIO_PIN_CNF_DIR_Input << GPIO_PIN_CNF_DIR_Pos) |
                                   (GPIO_PIN_CNF_PULL_Pullup << GPIO_PIN_CNF_PULL_Pos) |
                                   (GPIO_PIN_CNF_INPUT_Connect << GPIO_PIN_CNF_INPUT_Pos);
  NRF_GPIO->PIN_CNF[BUTTON4_PIN] = (GPIO_PIN_CNF_DIR_Input << GPIO_PIN_CNF_DIR_Pos) |
                                   (GPIO_PIN_CNF_PULL_Pullup << GPIO_PIN_CNF_PULL_Pos) |
                                   (GPIO_PIN_CNF_INPUT_Connect << GPIO_PIN_CNF_INPUT_Pos);

  NRF_PWM0->PRESCALER   = PWM_PRESCALER_PRESCALER_DIV_16; // 1 us
  NRF_PWM0->PSEL.OUT[0] = PWM_PIN_0;
  NRF_PWM0->PSEL.OUT[1] = PWM_PIN_1;
  NRF_PWM0->PSEL.OUT[2] = PWM_PIN_2;
  NRF_PWM0->MODE        = (PWM_MODE_UPDOWN_Up << PWM_MODE_UPDOWN_Pos);
  NRF_PWM0->DECODER     = (PWM_DECODER_LOAD_Individual   << PWM_DECODER_LOAD_Pos) |
                          (PWM_DECODER_MODE_RefreshCount << PWM_DECODER_MODE_Pos);
  NRF_PWM0->LOOP      = (PWM_LOOP_CNT_Disabled << PWM_LOOP_CNT_Pos);

  NRF_PWM0->COUNTERTOP = 20000; // 20ms period


  NRF_PWM0->SEQ[0].CNT = 4; //((sizeof(buf) / sizeof(uint16_t)) << PWM_SEQ_CNT_CNT_Pos);
  NRF_PWM0->SEQ[0].ENDDELAY = 0;
  NRF_PWM0->SEQ[0].PTR = (uint32_t)&m_buf[0];
  NRF_PWM0->SEQ[0].REFRESH = 0;
  NRF_PWM0->SHORTS = PWM_SHORTS_LOOPSDONE_SEQSTART0_Msk;

  NRF_PWM0->ENABLE = 1;

  NRF_PWM0->TASKS_SEQSTART[0] = 1;
  while (NRF_PWM0->EVENTS_SEQEND[0] == 0);
  NRF_PWM0->EVENTS_SEQEND[0] = 0;

  while (1)
  {
    if ((NRF_GPIO->IN & (1 << BUTTON1_PIN)) == 0)
    {
      roll(100);
    }
    else if ((NRF_GPIO->IN & (1 << BUTTON2_PIN)) == 0)
    {
      roll(900);
    }
    else
    {
      roll(500);
    }

    if ((NRF_GPIO->IN & (1 << BUTTON3_PIN)) == 0)
    {
      pitch(100);
    }
    else if ((NRF_GPIO->IN & (1 << BUTTON4_PIN)) == 0)
    {
      pitch(900);
    }
    else
    {
      pitch(500);
    }

    update_servos();
    NRF_PWM0->TASKS_SEQSTART[0] = 1;
    while (NRF_PWM0->EVENTS_SEQEND[0] == 0);
    NRF_PWM0->EVENTS_SEQEND[0] = 0;
  }
  return 0;
}
