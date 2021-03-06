require_relative 'gen/tasks_base'

module Asana
  module Resources
    # The _task_ is the basic object around which many operations in Asana are
    # centered. In the Asana application, multiple tasks populate the middle pane
    # according to some view parameters, and the set of selected tasks determines
    # the more detailed information presented in the details pane.
    class Task < TasksBase

      include AttachmentUploading

      include EventSubscription


      attr_reader :gid

      attr_reader :resource_type

      attr_reader :resource_subtype

      attr_reader :assignee

      attr_reader :assignee_status

      attr_reader :created_at

      attr_reader :completed

      attr_reader :completed_at

      attr_reader :custom_fields

      attr_reader :dependencies

      attr_reader :dependents

      attr_reader :due_on

      attr_reader :due_at

      attr_reader :external

      attr_reader :followers

      attr_reader :is_rendered_as_separator

      attr_reader :liked

      attr_reader :likes

      attr_reader :memberships

      attr_reader :modified_at

      attr_reader :name

      attr_reader :notes

      attr_reader :html_notes

      attr_reader :num_likes

      attr_reader :num_subtasks

      attr_reader :parent

      attr_reader :projects

      attr_reader :start_on

      attr_reader :workspace

      attr_reader :tags

      class << self
        # Returns the plural name of the resource.
        def plural_name
          'tasks'
        end

        # Creating a new task is as easy as POSTing to the `/tasks` endpoint
        # with a data block containing the fields you'd like to set on the task.
        # Any unspecified fields will take on default values.
        #
        # Every task is required to be created in a specific workspace, and this
        # workspace cannot be changed once set. The workspace need not be set
        # explicitly if you specify `projects` or a `parent` task instead.
        #
        # `projects` can be a comma separated list of projects, or just a single
        # project the task should belong to.
        #
        # workspace - [Gid] The workspace to create a task in.
        # options - [Hash] the request I/O options.
        # data - [Hash] the attributes to post.
        def create(client, workspace: nil, options: {}, **data)
          with_params = data.merge(workspace: workspace).reject { |_,v| v.nil? || Array(v).empty? }
          self.new(parse(client.post("/tasks", body: with_params, options: options)).first, client: client)
        end

        # Creating a new task is as easy as POSTing to the `/tasks` endpoint
        # with a data block containing the fields you'd like to set on the task.
        # Any unspecified fields will take on default values.
        #
        # Every task is required to be created in a specific workspace, and this
        # workspace cannot be changed once set. The workspace need not be set
        # explicitly if you specify a `project` or a `parent` task instead.
        #
        # workspace - [Gid] The workspace to create a task in.
        # options - [Hash] the request I/O options.
        # data - [Hash] the attributes to post.
        def create_in_workspace(client, workspace: required("workspace"), options: {}, **data)

          self.new(parse(client.post("/workspaces/#{workspace}/tasks", body: data, options: options)).first, client: client)
        end

        # Returns the complete task record for a single task.
        #
        # id - [Gid] The task to get.
        # options - [Hash] the request I/O options.
        def find_by_id(client, id, options: {})

          self.new(parse(client.get("/tasks/#{id}", options: options)).first, client: client)
        end

        # Returns the compact task records for all tasks within the given project,
        # ordered by their priority within the project.
        #
        # project - [Gid] The project in which to search for tasks.
        # per_page - [Integer] the number of records to fetch per page.
        # options - [Hash] the request I/O options.
        def find_by_project(client, project: nil, projectId: nil, per_page: 20, options: {})
          params = { limit: per_page }.reject { |_,v| v.nil? || Array(v).empty? }
          Collection.new(parse(client.get("/projects/#{project != nil ? project : projectId}/tasks", params: params, options: options)), type: self, client: client)
        end

        # Returns the compact task records for all tasks with the given tag.
        #
        # tag - [Gid] The tag in which to search for tasks.
        # per_page - [Integer] the number of records to fetch per page.
        # options - [Hash] the request I/O options.
        def find_by_tag(client, tag: required("tag"), per_page: 20, options: {})
          params = { limit: per_page }.reject { |_,v| v.nil? || Array(v).empty? }
          Collection.new(parse(client.get("/tags/#{tag}/tasks", params: params, options: options)), type: self, client: client)
        end

        # <b>Board view only:</b> Returns the compact section records for all tasks within the given section.
        #
        # section - [Gid] The section in which to search for tasks.
        # per_page - [Integer] the number of records to fetch per page.
        # options - [Hash] the request I/O options.
        def find_by_section(client, section: required("section"), per_page: 20, options: {})
          params = { limit: per_page }.reject { |_,v| v.nil? || Array(v).empty? }
          Collection.new(parse(client.get("/sections/#{section}/tasks", params: params, options: options)), type: self, client: client)
        end

        # Returns the compact list of tasks in a user's My Tasks list. The returned
        # tasks will be in order within each assignee status group of `Inbox`,
        # `Today`, and `Upcoming`.
        #
        # **Note:** tasks in `Later` have a different ordering in the Asana web app
        # than the other assignee status groups; this endpoint will still return
        # them in list order in `Later` (differently than they show up in Asana,
        # but the same order as in Asana's mobile apps).
        #
        # **Note:** Access control is enforced for this endpoint as with all Asana
        # API endpoints, meaning a user's private tasks will be filtered out if the
        # API-authenticated user does not have access to them.
        #
        # **Note:** Both complete and incomplete tasks are returned by default
        # unless they are filtered out (for example, setting `completed_since=now`
        # will return only incomplete tasks, which is the default view for "My
        # Tasks" in Asana.)
        #
        # user_task_list - [Gid] The user task list in which to search for tasks.
        # completed_since - [String] Only return tasks that are either incomplete or that have been
        # completed since this time.
        #
        # per_page - [Integer] the number of records to fetch per page.
        # options - [Hash] the request I/O options.
        def find_by_user_task_list(client, user_task_list: required("user_task_list"), completed_since: nil, per_page: 20, options: {})
          params = { completed_since: completed_since, limit: per_page }.reject { |_,v| v.nil? || Array(v).empty? }
          Collection.new(parse(client.get("/user_task_lists/#{user_task_list}/tasks", params: params, options: options)), type: self, client: client)
        end

        # Returns the compact task records for some filtered set of tasks. Use one
        # or more of the parameters provided to filter the tasks returned. You must
        # specify a `project`, `section`, `tag`, or `user_task_list` if you do not
        # specify `assignee` and `workspace`.
        #
        # assignee - [String] The assignee to filter tasks on.
        # workspace - [Gid] The workspace or organization to filter tasks on.
        # project - [Gid] The project to filter tasks on.
        # section - [Gid] The section to filter tasks on.
        # tag - [Gid] The tag to filter tasks on.
        # user_task_list - [Gid] The user task list to filter tasks on.
        # completed_since - [String] Only return tasks that are either incomplete or that have been
        # completed since this time.
        #
        # modified_since - [String] Only return tasks that have been modified since the given time.
        #
        # per_page - [Integer] the number of records to fetch per page.
        # options - [Hash] the request I/O options.
        # Notes:
        #
        # If you specify `assignee`, you must also specify the `workspace` to filter on.
        #
        # If you specify `workspace`, you must also specify the `assignee` to filter on.
        #
        # Currently, this is only supported in board views.
        #
        # A task is considered "modified" if any of its properties change,
        # or associations between it and other objects are modified (e.g.
        # a task being added to a project). A task is not considered modified
        # just because another object it is associated with (e.g. a subtask)
        # is modified. Actions that count as modifying the task include
        # assigning, renaming, completing, and adding stories.
        def find_all(client, assignee: nil, workspace: nil, project: nil, section: nil, tag: nil, user_task_list: nil, completed_since: nil, modified_since: nil, per_page: 20, options: {})
          params = { assignee: assignee, workspace: workspace, project: project, section: section, tag: tag, user_task_list: user_task_list, completed_since: completed_since, modified_since: modified_since, limit: per_page }.reject { |_,v| v.nil? || Array(v).empty? }
          Collection.new(parse(client.get("/tasks", params: params, options: options)), type: self, client: client)
        end

        # The search endpoint allows you to build complex queries to find and fetch exactly the data you need from Asana. For a more comprehensive description of all the query parameters and limitations of this endpoint, see our [long-form documentation](/developers/documentation/getting-started/search-api) for this feature.
        #
        # workspace - [Gid] The workspace or organization in which to search for tasks.
        # resource_subtype - [Enum] Filters results by the task's resource_subtype.
        #
        # per_page - [Integer] the number of records to fetch per page.
        # options - [Hash] the request I/O options.
        def search_in_workspace(client, workspace: required("workspace"), resource_subtype: nil, per_page: 20, options: {})
          params = { resource_subtype: resource_subtype, limit: per_page }.reject { |_,v| v.nil? || Array(v).empty? }
          if options[:params]
            params.merge!(options[:params])
          end
          Collection.new(parse(client.get("/workspaces/#{workspace}/tasks/search", params: params, options: options)), type: Resource, client: client)
        end
        alias_method :search, :search_in_workspace
      end

      # A specific, existing task can be updated by making a PUT request on the
      # URL for that task. Only the fields provided in the `data` block will be
      # updated; any unspecified fields will remain unchanged.
      #
      # When using this method, it is best to specify only those fields you wish
      # to change, or else you may overwrite changes made by another user since
      # you last retrieved the task.
      #
      # Returns the complete updated task record.
      #
      # options - [Hash] the request I/O options.
      # data - [Hash] the attributes to post.
      def update(options: {}, **data)

        refresh_with(parse(client.put("/tasks/#{gid}", body: data, options: options)).first)
      end

      # A specific, existing task can be deleted by making a DELETE request on the
      # URL for that task. Deleted tasks go into the "trash" of the user making
      # the delete request. Tasks can be recovered from the trash within a period
      # of 30 days; afterward they are completely removed from the system.
      #
      # Returns an empty data record.
      def delete()

        client.delete("/tasks/#{gid}") && true
      end

      # Creates and returns a job that will asynchronously handle the duplication.
      #
      # name - [String] The name of the new task.
      # include - [Array] The fields that will be duplicated to the new task.
      #
      # options - [Hash] the request I/O options.
      # data - [Hash] the attributes to post.
      def duplicate_task(name: required("name"), include: nil, options: {}, **data)
        with_params = data.merge(name: name, include: include).reject { |_,v| v.nil? || Array(v).empty? }
        Resource.new(parse(client.post("/tasks/#{gid}/duplicate", body: with_params, options: options)).first, client: client)
      end

      # Returns the compact representations of all of the dependencies of a task.
      #
      # options - [Hash] the request I/O options.
      def dependencies(options: {})

        Collection.new(parse(client.get("/tasks/#{gid}/dependencies", options: options)), type: self.class, client: client)
      end

      # Returns the compact representations of all of the dependents of a task.
      #
      # options - [Hash] the request I/O options.
      def dependents(options: {})

        Collection.new(parse(client.get("/tasks/#{gid}/dependents", options: options)), type: self.class, client: client)
      end

      # Marks a set of tasks as dependencies of this task, if they are not
      # already dependencies. *A task can have at most 15 dependencies.*
      #
      # dependencies - [Array] An array of task IDs that this task should depend on.
      # options - [Hash] the request I/O options.
      # data - [Hash] the attributes to post.
      def add_dependencies(dependencies: required("dependencies"), options: {}, **data)
        with_params = data.merge(dependencies: dependencies).reject { |_,v| v.nil? || Array(v).empty? }
        Collection.new(parse(client.post("/tasks/#{gid}/addDependencies", body: with_params, options: options)), type: self.class, client: client)
      end

      # Marks a set of tasks as dependents of this task, if they are not already
      # dependents. *A task can have at most 30 dependents.*
      #
      # dependents - [Array] An array of task IDs that should depend on this task.
      # options - [Hash] the request I/O options.
      # data - [Hash] the attributes to post.
      def add_dependents(dependents: required("dependents"), options: {}, **data)
        with_params = data.merge(dependents: dependents).reject { |_,v| v.nil? || Array(v).empty? }
        Collection.new(parse(client.post("/tasks/#{gid}/addDependents", body: with_params, options: options)), type: self.class, client: client)
      end

      # Unlinks a set of dependencies from this task.
      #
      # dependencies - [Array] An array of task IDs to remove as dependencies.
      # options - [Hash] the request I/O options.
      # data - [Hash] the attributes to post.
      def remove_dependencies(dependencies: required("dependencies"), options: {}, **data)
        with_params = data.merge(dependencies: dependencies).reject { |_,v| v.nil? || Array(v).empty? }
        Collection.new(parse(client.post("/tasks/#{gid}/removeDependencies", body: with_params, options: options)), type: self.class, client: client)
      end

      # Unlinks a set of dependents from this task.
      #
      # dependents - [Array] An array of task IDs to remove as dependents.
      # options - [Hash] the request I/O options.
      # data - [Hash] the attributes to post.
      def remove_dependents(dependents: required("dependents"), options: {}, **data)
        with_params = data.merge(dependents: dependents).reject { |_,v| v.nil? || Array(v).empty? }
        Collection.new(parse(client.post("/tasks/#{gid}/removeDependents", body: with_params, options: options)), type: self.class, client: client)
      end

      # Adds each of the specified followers to the task, if they are not already
      # following. Returns the complete, updated record for the affected task.
      #
      # followers - [Array] An array of followers to add to the task.
      # options - [Hash] the request I/O options.
      # data - [Hash] the attributes to post.
      def add_followers(followers: required("followers"), options: {}, **data)
        with_params = data.merge(followers: followers).reject { |_,v| v.nil? || Array(v).empty? }
        refresh_with(parse(client.post("/tasks/#{gid}/addFollowers", body: with_params, options: options)).first)
      end

      # Removes each of the specified followers from the task if they are
      # following. Returns the complete, updated record for the affected task.
      #
      # followers - [Array] An array of followers to remove from the task.
      # options - [Hash] the request I/O options.
      # data - [Hash] the attributes to post.
      def remove_followers(followers: required("followers"), options: {}, **data)
        with_params = data.merge(followers: followers).reject { |_,v| v.nil? || Array(v).empty? }
        refresh_with(parse(client.post("/tasks/#{gid}/removeFollowers", body: with_params, options: options)).first)
      end

      # Returns a compact representation of all of the projects the task is in.
      #
      # per_page - [Integer] the number of records to fetch per page.
      # options - [Hash] the request I/O options.
      def projects(per_page: 20, options: {})
        params = { limit: per_page }.reject { |_,v| v.nil? || Array(v).empty? }
        Collection.new(parse(client.get("/tasks/#{gid}/projects", params: params, options: options)), type: Project, client: client)
      end

      # Adds the task to the specified project, in the optional location
      # specified. If no location arguments are given, the task will be added to
      # the end of the project.
      #
      # `addProject` can also be used to reorder a task within a project or section that
      # already contains it.
      #
      # At most one of `insert_before`, `insert_after`, or `section` should be
      # specified. Inserting into a section in an non-order-dependent way can be
      # done by specifying `section`, otherwise, to insert within a section in a
      # particular place, specify `insert_before` or `insert_after` and a task
      # within the section to anchor the position of this task.
      #
      # Returns an empty data block.
      #
      # project - [Gid] The project to add the task to.
      # insert_after - [Gid] A task in the project to insert the task after, or `null` to
      # insert at the beginning of the list.
      #
      # insert_before - [Gid] A task in the project to insert the task before, or `null` to
      # insert at the end of the list.
      #
      # section - [Gid] A section in the project to insert the task into. The task will be
      # inserted at the bottom of the section.
      #
      # options - [Hash] the request I/O options.
      # data - [Hash] the attributes to post.
      def add_project(project: required("project"), insert_after: nil, insert_before: nil, section: nil, options: {}, **data)
        with_params = data.merge(project: project, insert_after: insert_after, insert_before: insert_before, section: section).reject { |_,v| v.nil? || Array(v).empty? }
        client.post("/tasks/#{gid}/addProject", body: with_params, options: options) && true
      end

      # Removes the task from the specified project. The task will still exist
      # in the system, but it will not be in the project anymore.
      #
      # Returns an empty data block.
      #
      # project - [Gid] The project to remove the task from.
      # options - [Hash] the request I/O options.
      # data - [Hash] the attributes to post.
      def remove_project(project: required("project"), options: {}, **data)
        with_params = data.merge(project: project).reject { |_,v| v.nil? || Array(v).empty? }
        client.post("/tasks/#{gid}/removeProject", body: with_params, options: options) && true
      end

      # Returns a compact representation of all of the tags the task has.
      #
      # per_page - [Integer] the number of records to fetch per page.
      # options - [Hash] the request I/O options.
      def tags(per_page: 20, options: {})
        params = { limit: per_page }.reject { |_,v| v.nil? || Array(v).empty? }
        Collection.new(parse(client.get("/tasks/#{gid}/tags", params: params, options: options)), type: Tag, client: client)
      end

      # Adds a tag to a task. Returns an empty data block.
      #
      # tag - [Gid] The tag to add to the task.
      # options - [Hash] the request I/O options.
      # data - [Hash] the attributes to post.
      def add_tag(tag: required("tag"), options: {}, **data)
        with_params = data.merge(tag: tag).reject { |_,v| v.nil? || Array(v).empty? }
        client.post("/tasks/#{gid}/addTag", body: with_params, options: options) && true
      end

      # Removes a tag from the task. Returns an empty data block.
      #
      # tag - [Gid] The tag to remove from the task.
      # options - [Hash] the request I/O options.
      # data - [Hash] the attributes to post.
      def remove_tag(tag: required("tag"), options: {}, **data)
        with_params = data.merge(tag: tag).reject { |_,v| v.nil? || Array(v).empty? }
        client.post("/tasks/#{gid}/removeTag", body: with_params, options: options) && true
      end

      # Returns a compact representation of all of the subtasks of a task.
      #
      # per_page - [Integer] the number of records to fetch per page.
      # options - [Hash] the request I/O options.
      def subtasks(per_page: 20, options: {})
        params = { limit: per_page }.reject { |_,v| v.nil? || Array(v).empty? }
        Collection.new(parse(client.get("/tasks/#{gid}/subtasks", params: params, options: options)), type: self.class, client: client)
      end

      # Creates a new subtask and adds it to the parent task. Returns the full record
      # for the newly created subtask.
      #
      # options - [Hash] the request I/O options.
      # data - [Hash] the attributes to post.
      def add_subtask(options: {}, **data)

        self.class.new(parse(client.post("/tasks/#{gid}/subtasks", body: data, options: options)).first, client: client)
      end

      # Changes the parent of a task. Each task may only be a subtask of a single
      # parent, or no parent task at all. Returns an empty data block. When using `insert_before` and `insert_after`,
      # at most one of those two options can be specified, and they must already be subtasks
      # of the parent.
      #
      # parent - [Gid] The new parent of the task, or `null` for no parent.
      # insert_after - [Gid] A subtask of the parent to insert the task after, or `null` to
      # insert at the beginning of the list.
      #
      # insert_before - [Gid] A subtask of the parent to insert the task before, or `null` to
      # insert at the end of the list.
      #
      # options - [Hash] the request I/O options.
      # data - [Hash] the attributes to post.
      def set_parent(parent: required("parent"), insert_after: nil, insert_before: nil, options: {}, **data)
        with_params = data.merge(parent: parent, insert_after: insert_after, insert_before: insert_before).reject { |_,v| v.nil? || Array(v).empty? }
        client.post("/tasks/#{gid}/setParent", body: with_params, options: options) && true
      end

      # Returns a compact representation of all of the stories on the task.
      #
      # per_page - [Integer] the number of records to fetch per page.
      # options - [Hash] the request I/O options.
      def stories(per_page: 20, options: {})
        params = { limit: per_page }.reject { |_,v| v.nil? || Array(v).empty? }
        Collection.new(parse(client.get("/tasks/#{gid}/stories", params: params, options: options)), type: Story, client: client)
      end

      # Adds a comment to a task. The comment will be authored by the
      # currently authenticated user, and timestamped when the server receives
      # the request.
      #
      # Returns the full record for the new story added to the task.
      #
      # text - [String] The plain text of the comment to add.
      # options - [Hash] the request I/O options.
      # data - [Hash] the attributes to post.
      def add_comment(text: required("text"), options: {}, **data)
        with_params = data.merge(text: text).reject { |_,v| v.nil? || Array(v).empty? }
        Story.new(parse(client.post("/tasks/#{gid}/stories", body: with_params, options: options)).first, client: client)
      end

      # Insert or reorder tasks in a user's My Tasks list. If the task was not
      # assigned to the owner of the user task list it will be reassigned when
      # this endpoint is called. If neither `insert_before` nor `insert_after`
      # are provided the task will be inserted at the top of the assignee's
      # inbox.
      #
      # Returns an empty data block.
      #
      # user_task_list - [Gid] Globally unique identifier for the user task list.
      #
      # insert_before - [Gid] Insert the task before the task specified by this field. The inserted
      # task will inherit the `assignee_status` of this task. `insert_before`
      # and `insert_after` parameters cannot both be specified.
      #
      # insert_after - [Gid] Insert the task after the task specified by this field. The inserted
      # task will inherit the `assignee_status` of this task. `insert_before`
      # and `insert_after` parameters cannot both be specified.
      #
      # options - [Hash] the request I/O options.
      # data - [Hash] the attributes to post.
      def insert_in_user_task_list(user_task_list: required("user_task_list"), insert_before: nil, insert_after: nil, options: {}, **data)
        with_params = data.merge(insert_before: insert_before, insert_after: insert_after).reject { |_,v| v.nil? || Array(v).empty? }
        client.post("/user_task_lists/#{user_task_list}/tasks/insert", body: with_params, options: options) && true
      end

    end
  end
end
