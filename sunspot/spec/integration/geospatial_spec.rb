require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe "geospatial search" do
  describe "filtering by radius" do
    before :all do
      Sunspot.remove_all

      @post = Post.new(:title       => "Howdy",
                       :coordinates => Sunspot::Util::Coordinates.new(32, -68))
      Sunspot.index!(@post)
    end

    it "matches posts within the radius" do
      results = Sunspot.search(Post) {
        with(:coordinates_solr4).in_radius(32, -68, 1)
      }.results

      results.should include(@post)
    end

    it "filters out posts not in the radius" do
      results = Sunspot.search(Post) {
        with(:coordinates_solr4).in_radius(33, -68, 1)
      }.results

      results.should_not include(@post)
    end

    it "allows conjunction queries with radius" do
      results = Sunspot.search(Post) {
        any_of do
          with(:coordinates_solr4).in_radius(32, -68, 1)
          with(:coordinates_solr4).in_radius(35, 68, 1)
        end
      }.results

      results.should include(@post)
    end

    it "allows conjunction queries with bounding box" do
      results = Sunspot.search(Post) {
        any_of do
          with(:coordinates_new).in_bounding_box([31, -69], [33, -67])
          with(:coordinates_new).in_bounding_box([35, 68], [36, 69])
        end
      }.results

      results.should include(@post)
    end
  end

  describe "filtering by bounding box" do
    before :all do
      Sunspot.remove_all

      @post = Post.new(:title       => "Howdy",
                       :coordinates => Sunspot::Util::Coordinates.new(32, -68))
      Sunspot.index!(@post)
    end

    it "matches post within the bounding box" do
      results = Sunspot.search(Post) {
        with(:coordinates_solr4).in_bounding_box [31, -69], [33, -67]
      }.results

      results.should include(@post)
    end

    it "filters out posts not in the bounding box" do
      results = Sunspot.search(Post) {
        with(:coordinates_solr4).in_bounding_box [20, -70], [21, -69]
      }.results

      results.should_not include(@post)
    end
  end

  describe "filtering posts that contain a point" do
    describe "within a single polygon" do
      before :all do
        Sunspot.remove_all

        @post = Post.new(:title       => "Howdy",
                         :boundary => {:polygons => [[[1,1],[1,7],[3,12],[5,6],[5,4],[1,1]]]})
        Sunspot.index!(@post)
      end

      it "matches post within the polygon" do
        results = Sunspot.search(Post) {
          with(:boundary).containing_point [2, 2]
        }.results

        results.should include(@post)
      end

      it "filters out posts not in the polygon" do
        results = Sunspot.search(Post) {
          with(:boundary).containing_point [2, 15]
        }.results

        results.should_not include(@post)
      end
    end

    describe "within a multi-polygon" do
      before :all do
        Sunspot.remove_all

        @post = Post.new(:title       => "Howdy",
                         :boundary => {:polygons => [
                           [[1,1],[1,7],[3,12],[5,6],[5,4],[1,1]],
                           [[-1,-1],[-1,-7],[-3,-12],[-5,-6],[-5,-4],[-1,-1]],
                           [[51,51],[51,57],[53,62],[55,56],[55,54],[51,51]],

        ]})
        Sunspot.index!(@post)
      end

      it "matches post containing points in either polygon" do
        results = Sunspot.search(Post) {
          with(:boundary).containing_point [2, 2]
        }.results

        results.should include(@post)

        results = Sunspot.search(Post) {
          with(:boundary).containing_point [-2, -2]
        }.results

        results.should include(@post)

        results = Sunspot.search(Post) {
          with(:boundary).containing_point [52, 52]
        }.results

        results.should include(@post)
      end

      it "filters out posts not containing points" do
        results = Sunspot.search(Post) {
          with(:boundary).containing_point [2, 15]
        }.results

        results.should_not include(@post)

        results = Sunspot.search(Post) {
          with(:boundary).containing_point [-2, -15]
        }.results

        results.should_not include(@post)

        results = Sunspot.search(Post) {
          with(:boundary).containing_point [52, 65]
        }.results

        results.should_not include(@post)
      end
    end
  end

  describe "ordering by geodist" do
    before :all do
      Sunspot.remove_all

      @posts = [
        Post.new(:title => "Howdy", :coordinates => Sunspot::Util::Coordinates.new(34, -68)),
        Post.new(:title => "Howdy", :coordinates => Sunspot::Util::Coordinates.new(33, -68)),
        Post.new(:title => "Howdy", :coordinates => Sunspot::Util::Coordinates.new(32, -68))
      ]

      Sunspot.index!(@posts)
    end

    it "orders posts by distance ascending" do
      results = Sunspot.search(Post) {
        order_by_geodist(:coordinates_new, 32, -68)
      }.results

      results.should == @posts.reverse
    end

    it "orders posts by distance descending" do
      results = Sunspot.search(Post) {
        order_by_geodist(:coordinates_new, 32, -68, :desc)
      }.results

      results.should == @posts
    end
  end

  describe "ordering by geodist (solr4 spatial recursive tree type)" do
    before :all do
      Sunspot.remove_all

      @posts = [
        Post.new(:title => "Howdy", :coordinates => Sunspot::Util::Coordinates.new(34, -68)),
        Post.new(:title => "Howdy", :coordinates => Sunspot::Util::Coordinates.new(33, -68)),
        Post.new(:title => "Howdy", :coordinates => Sunspot::Util::Coordinates.new(32, -68))
      ]

      Sunspot.index!(@posts)
    end

    it "orders posts by distance ascending" do
      results = Sunspot.search(Post) {
        order_by_geodist(:coordinates_solr4, 32, -68)
      }.results

      results.should == @posts.reverse
    end

    it "orders posts by distance descending" do
      results = Sunspot.search(Post) {
        order_by_geodist(:coordinates_solr4, 32, -68, :desc)
      }.results

      results.should == @posts
    end
  end

  describe "boost by geodist (solr4 spatial recursive tree type)" do
    before :all do
      Sunspot.remove_all

      @posts = [
        Post.new(:title => "Howdy", :coordinates => Sunspot::Util::Coordinates.new(34, -68)),
        Post.new(:title => "Howdy", :coordinates => Sunspot::Util::Coordinates.new(33, -68)),
        Post.new(:title => "Howdy", :coordinates => Sunspot::Util::Coordinates.new(32, -68))
      ]

      Sunspot.index!(@posts)
    end

    it "when all else is equal, orders posts by distance ascending" do
      results = Sunspot.search(Post) {
        boost_by_inverse_of_geodist(:coordinates_solr4, 32, -68)
      }.results

      results.should == @posts.reverse
    end
  end

  describe "ordering by distance using geofilt (solr4 spatial recursive tree type)" do
    before :all do
      Sunspot.remove_all

      @posts = [
        Post.new(:title => "Howdy", :coordinates => Sunspot::Util::Coordinates.new(34, -68)),
        Post.new(:title => "Howdy", :coordinates => Sunspot::Util::Coordinates.new(33, -68)),
        Post.new(:title => "Howdy", :coordinates => Sunspot::Util::Coordinates.new(32, -68))
      ]

      Sunspot.index!(@posts)
    end

    it "orders posts by distance ascending" do
      results = Sunspot.search(Post) {
        order_by_distance(:coordinates_solr4, 32, -68)
      }.results

      results.should == @posts.reverse
    end

    it "orders posts by distance descending" do
      results = Sunspot.search(Post) {
        order_by_distance(:coordinates_solr4, 32, -68, :desc)
      }.results

      results.should == @posts
    end
  end
end
