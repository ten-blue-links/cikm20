
include ../../local.mk

TARGET = hostdocno
CPPNETLIB=../cpp-netlib
CXX = g++
CXXFLAGS = --std=c++11 -g -I$(INDRI_INCLUDE_PATH) \
	-I$(CPPNETLIB) \
	-I$(BOOST_INCLUDE_PATH) \
	-DHAVE_EXT_ATOMICITY=1 -DP_NEEDS_GNU_CXX_NAMESPACE=1
# link boost_system.a so we don't have to use `LD_LIBRARY_PATH` fuckery
LDFLAGS = -L$(INDRI_LIBRARY_PATH) \
		  -L$(CPPNETLIB)/build/libs/network/src \
		  -L$(BOOST_LIBRARY_PATH) \
		  -l:libboost_system.a \
		  -lcppnetlib-uri -lindri -lz -pthread

SRC = hostdocno.cpp
OBJS = $(SRC:.cpp=.o)

.PHONY: all
all: $(TARGET)

$(TARGET): $(OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

.PHONY: clean
clean:
	$(RM) $(TARGET) $(OBJS)
