// TrafficModel.h

#ifndef TRAFFIC_MODEL_H_STUB_2
#define TRAFFIC_MODEL_H_STUB_2

class TrafficWriteCommand;
class ConnectionModel;

class TrafficModel
{
public:
  virtual ~TrafficModel() {}
  virtual std::auto_ptr<TrafficModel> clone(void)=0;
  virtual Time addWrite(TrafficWriteCommand const & newWrite,
                        Time const & deadline)=0;
  virtual WriteResult writeToPeer(ConnectionModel * peer,
                                  Time const & previousTime)=0;
};

class NullTrafficModel : public TrafficModel
{
public:
  virtual ~NullTrafficModel() {}
  virtual std::auto_ptr<TrafficModel> clone(void)
  {
    return std::auto_ptr<TrafficModel>(new NullTrafficModel());
  }
  virtual Time addWrite(TrafficWriteCommand const &,
                        Time const &)
  {
    return Time();
  }
  virtual WriteResult writeToPeer(ConnectionModel * peer,
                                  Time const & previousTime)
  {
    WriteResult result;
    result.isConnected = false;
    result.bufferFull = false;
    result.nextWrite = Time();
    return result;
  }
};

#endif
