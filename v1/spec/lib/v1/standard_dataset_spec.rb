require 'v1/standard_dataset'

module V1

  describe StandardDataset do
    before(:each) do
      # No need to check this inside a unit test
      subject.stub(:endpoint_config_check)
    end

    context "Constants" do
      describe "SEARCH_RIVER_NAME" do
        it "is correct" do
          expect(V1::StandardDataset::SEARCH_RIVER_NAME).to eq 'dpla_river'
        end
      end
    end

    describe "#recreate_env!" do
      it "calls the correct methods in the correct order" do
        subject.should_receive(:recreate_index!)
        subject.should_receive(:import_test_dataset)
        subject.should_receive(:recreate_river!)
        subject.stub(:doc_count)
        subject.recreate_env!
        # puts "ElasticSearch docs: #{ doc_count }"
      end
    end

    describe "#recreate_index!" do

      it "re-creates the search index with correct name and mapping" do
        tire = mock
        tire.stub_chain(:response, :code) { 200 }
        Tire.should_receive(:index).with(V1::Config::SEARCH_INDEX).and_yield(tire)
        tire.should_receive(:delete)
        tire.should_receive(:create).with( { 'mappings' => V1::Schema::ELASTICSEARCH_MAPPING } )
        subject.should_not_receive(:import_test_dataset)
        subject.recreate_index!
      end

    end

    describe "#import_data_file" do
      before(:each) do
        subject.stub(:display_import_result)
      end
      it "imports the correct resource type" do
        tire = mock.as_null_object
        input_file = stub
        Tire.should_receive(:index).with(V1::Config::SEARCH_INDEX).and_yield(tire)

        subject.should_receive(:process_input_file).with('item', 'foo.json') { input_file }
        tire.should_receive(:import).with(input_file)
        subject.import_data_file('item', 'foo.json')
        
      end
      
    end

    describe "#import_test_dataset" do
      it "imports test data for all resources" do
        subject.should_receive(:import_data_file).with('item', V1::StandardDataset::ITEMS_JSON_FILE)
        #subject.should_receive(:import_data_file).with('collections', V1::StandardDataset::COLLECTIONS_JSON_FILE)
        subject.import_test_dataset
      end
    end

    describe "#process_input_file" do
      it "injects a new _type field with the resource param into loaded JSON" do
        file_stub = stub
        File.should_receive(:read).with(file_stub) { nil }
        JSON.stub(:load) { [ {'id' => 1}, {'id' => 2} ] }
        expect(subject.process_input_file('foo', file_stub))
          .to match_array(
                          [
                           {'id' => 1, '_type' => 'foo'},
                           {'id' => 2, '_type' => 'foo'}
                          ]
                          )
      end
      it "does not inject anything if the resource param is nil" do
        file_stub = stub
        File.should_receive(:read).with(file_stub) { nil }
        JSON.stub(:load) { [ {'id' => 1}, {'id' => 2} ] }
        expect(subject.process_input_file(nil, file_stub)).to match_array([ {'id' => 1}, {'id' => 2} ])
      end
      it "raises an error when there is invalid JSON in a test data file" do
        File.stub(:read) { "invalid json here\nAnd on the second line" }
        expect {
          expect(subject.process_input_file('foo', stub))
        }.to raise_error /JSON parse error/i
      end
    end

    describe "#recreate_river" do
      it "sleeps between river delete and create" do

        subject.should_receive(:delete_river!)
        subject.should_receive(:sleep).with(any_args)
        subject.should_receive(:create_river)
        subject.recreate_river!
      end
    end

  end

end
