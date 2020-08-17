
#include <iostream>
#include <cmath>

#include "indri/Repository.hpp"
#include "indri/CompressedCollection.hpp"

#include "boost/network/uri.hpp"

// Dump host and docno

int main(int argc, char **argv)
{
  if (argc != 2) {
    std::cerr << "usage: " << argv[0]
              << " <repo>" << std::endl;
    return EXIT_FAILURE;
  }

  using namespace boost::network;

  std::string repository_name = argv[1];

  indri::collection::Repository repo;
  repo.openRead(repository_name);
  indri::collection::Repository::index_state state = repo.indexes();
  const auto &index = (*state)[0];

  indri::collection::CompressedCollection *collection = repo.collection();
  indri::index::TermListFileIterator *it = index->termListFileIterator();

  int id = index->documentBase();
  size_t total_docs = index->documentCount();
  size_t c = 0;
  it->startIteration();
  while (!it->finished()) {
    std::string doc_name = collection->retrieveMetadatum(id, "docno");
    std::string url = collection->retrieveMetadatum(id, "url");

    uri::uri instance(url);
    std::cout << doc_name << "," << instance.host() << std::endl;

    if (id % 10000 == 0 || id == index->documentBase() || size_t(id) == total_docs) {
      static size_t last_len = 0;
      std::ostringstream oss;
      double progress = double(id) / double(total_docs);
      progress *= 100;
      std::cerr << std::string(last_len, '\b');
      oss.str("");
      oss << "documents processed: " << id << " (" << int(progress) << "%)";
      last_len = oss.str().size();
      std::cerr << oss.str();
    }

    id++;
    it->nextEntry();
  }
  std::cerr << std::endl;

  return 0;
}
