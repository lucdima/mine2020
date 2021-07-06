pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

function _init(size,bombs,selected_size_and_bombs,sound_enable)
    make_game()
    make_sound_manager(sound_enable)
    make_intro()
    make_credits()
    make_board(size,bombs)
    make_cursor(flr(board.size/2-1),flr(board.size/2))
    make_cursor_2(flr(board.size/2),flr(board.size/2))
    make_timer()
    make_hud(timer)
    make_menu()
    make_options_menu(selected_size_and_bombs,sound_manager.sound_enable)
end

function _update()
    if game.state==0 then
        intro:update()
        menu:update()
    elseif game.state==1 then
        cursor:action()
        if game.players==2 then cursor_2:action() end
        timer:update()
    elseif game.state==2 then
        if any_key() then
            _init(board.size,board.total_bombs,options_menu.menu_items[1].selected,sound_manager.sound_enable)
        end
    elseif game.state==3 then
        if any_key() then
            _init(board.size,board.total_bombs,options_menu.menu_items[1].selected,sound_manager.sound_enable)
        end
    elseif game.state==4 then
        intro:update()
        options_menu:update()
    elseif game.state==5 then
        credits:update()
    end
end

function _draw()
    if game.state==0 then -- intro
        intro:draw()
        menu:draw()
    elseif game.state==1 then -- game
        board:draw()
        cursor:draw()
        if game.players==2 then cursor_2:draw() end
        hud:draw()
    elseif game.state==2 or game.state==3 then -- game over
        hud:draw()
        cursor:draw()
        if game.players==2 then cursor_2:draw() end
    elseif game.state==4 then -- options
        intro:draw()
        options_menu:draw()
    elseif game.state==5 then -- credits
        credits:draw()
    end
end

function make_game()
    --- game.state=0 is intro
    --- game.state=1 game
    --- game.state=2 is gameover loose
    --- game.state=3 is gameover win
    --- game.state=4 is options
    --- game.state=5 is credits
    game={
        state=0,
        start=0,
        players=1
    }
end

function make_intro()
    cls(13)
    intro={
        draw=function(self)
            spr(2,10,10)
            spr(2,20,10)
            spr(3,20,10)
            spr(5,30,10)
            print(".mine 2020", 40,12,7)
            spr(2,110,100)
            spr(2,100,110)
            spr(2,110,110)
            print("(c) 2020 lucas dima", 10,112,6)
        end,
        update=function(self)
        end
    }
end

function make_credits()
    cls(13)
    credits={
        draw=function(self)
            print("mine 2020 was created as a\nfirst experiment in pico-8\ndevelopment.\n\nit is really delightful to code\nin this awesome platform.\n\nthis game is dedicated to my\nfriend lautaro, who is the\nbest mine sweeper player\ni've ever known!\n\nthanks to press over and it's\ncrew for showing\nme the existence of pico-8\nhttps://pressover.news/\n\n(c) 2020 lucas dima.\nberlin, germany\nthis is free software (gpl.v3)\n", 1, 1)
        end,
        update=function(self)
            if any_key() then
                cls(13)
                game.state=0
            end
        end,
    }
end

function make_menu()
    menu={
        bg_color=13,
        font_color=6,
        bg_color_selected=1,
        font_color_selected=7,
        selected=1,
        vertical_margin=2,
        horizontal_margin=3,
        menu_items={
            '1 player game',
            '2 players game',
            'options',
            'credits',
        },
        full_width=0,
        full_height=0,
        draw=function(self)
            local start_x=(128-self.full_width)/2
            local start_y=(128-self.full_height)/2
            local line_height=5+self.vertical_margin*2
            for i,menu_element in pairs(self.menu_items) do
                local font_color=self.font_color
                local bg_color=self.bg_color
                if i==self.selected then
                    font_color=self.font_color_selected
                    bg_color=self.bg_color_selected
                end
                local text_width=(#menu_element*4-2)
                rectfill(start_x,start_y+line_height*(i-1)+1,start_x+self.full_width,start_y+line_height*i,bg_color)
                print(menu_element,(128-text_width)/2,(start_y+line_height*(i-1)+1)+self.vertical_margin,font_color)
            end
        end,
        set_full_width=function(self)
            local max_width=0
            for menu_element in all(self.menu_items) do
                if #menu_element>max_width then
                    max_width=#menu_element
                end
            end
            self.full_width=max_width*4+self.horizontal_margin*2-2
        end,
        set_full_height=function(self)
            self.full_height=#self.menu_items*(5+self.vertical_margin*2)
        end,
        update=function(self)
            if (btnp(2) and self.selected>1) self.selected-=1
            if (btnp(3) and self.selected<#self.menu_items) self.selected+=1
            if (btnp(4) or btnp(5)) then
                cls(13)
                if self.selected==1then
                    game.state=1
                    game.players=1
                    sound_manager:play_start()
                elseif self.selected==2 then
                    game.state=1
                    game.players=2
                    sound_manager:play_start()
                elseif self.selected==3 then
                    game.state=4 -- options
                elseif self.selected==4 then
                    game.state=5 -- credits
                end
            end
        end,
    }
    menu:set_full_width()
    menu:set_full_height()
end

function make_board_size_and_bombs_menu_item(selected)
    if selected==nil then selected=7 end
    local name=''
    local option_display={
        ' 5x5 - 5 bombs ',
        ' 5x5 - 10 bombs ',
        ' 5x5 - 20 bombs ',
        ' 8x8 - 10 bombs',
        ' 8x8 - 20 bombs',
        ' 8x8 - 30 bombs',
        ' 10x10 - 10 bombs',
        ' 10x10 - 30 bombs',
        ' 10x10 - 50 bombs',
        ' 13x13 - 12 bombs',
        ' 13x13 - 30 bombs',
        ' 13x13 - 50 bombs',
    }
    local option_values={
        {size=5,bombs=5,},
        {size=5,bombs=10,},
        {size=5,bombs=20,},
        {size=8,bombs=10,},
        {size=8,bombs=20,},
        {size=8,bombs=30,},
        {size=10,bombs=10,},
        {size=10,bombs=20,},
        {size=10,bombs=50,},
        {size=13,bombs=12,},
        {size=13,bombs=30,},
        {size=13,bombs=50,},
    }
    local properties={}
    local board_size_menu_item=make_option_menu_items(name,option_display,option_values,selected,properties)

    return board_size_menu_item
end

function make_sound_menu_item(selected)
    if selected==nil then selected=1 end
    local name='sound'
    local option_display={' on', ' off'}
    local option_values={true,false}
    local selected=selected
    local properties={}

    return make_option_menu_items(name,option_display,option_values,selected,properties)
end

function make_return_menu_item()
    local name='return'
    local option_display={''}
    local option_values={''}
    local selected=1
    local properties={}

    return make_option_menu_items(name,option_display,option_values,selected,properties)
end

function make_option_menu_items(name, option_display,option_values,selected,properties)
    item={
        name=name,
        option_display=option_display,
        option_values=option_values,
        selected=selected,
        display=function(self,i)
            return self.name..self.option_display[i]
        end,
    }
    for key,value in pairs(properties) do
        item[key] = value
    end

    return item
end

function make_options_menu(selected_size_and_bombs,sound)
    local board_size_menu_item=make_board_size_and_bombs_menu_item(selected_size_and_bombs)
    local selected_sound=1
    if sound==false then selected_sound=2 end
    local sound_menu_item=make_sound_menu_item(selected_sound)
    local return_menu_item=make_return_menu_item()

    options_menu={
        bg_color=13,
        font_color=6,
        bg_color_selected=1,
        font_color_selected=7,
        selected=1,
        exit_option=3,
        vertical_margin=2, -- this is in pixels
        horizontal_margin=3, -- this is in pixels
        menu_items={
            board_size_menu_item,
            sound_menu_item,
            return_menu_item,
        },
        full_width=0,
        full_height=0,
        draw=function(self)
            local start_x=(128-self.full_width)/2
            local start_y=(128-self.full_height)/2
            local line_height=5+self.vertical_margin*2
            for i,menu_element in pairs(self.menu_items) do
                local font_color=self.font_color
                local bg_color=self.bg_color
                if i==self.selected then
                    font_color=self.font_color_selected
                    bg_color=self.bg_color_selected
                end
                local text=menu_element:display(menu_element.selected)
                local text_width=(#text*4-2)
                rectfill(start_x,start_y+line_height*(i-1)+1,start_x+self.full_width,start_y+line_height*i,bg_color)
                print(text,(128-text_width)/2,(start_y+line_height*(i-1)+1)+self.vertical_margin,font_color)
            end
        end,
        set_full_width=function(self)
            local max_width=0
            for menu_element in all(self.menu_items) do
                for i=1,#menu_element.option_display do
                    -- get max width from all options
                    local text=menu_element:display(i)
                    if #text>max_width then
                        max_width=#text
                    end
                end
            end
            self.full_width=max_width*4+self.horizontal_margin*2-2
        end,
        set_full_height=function(self)
            self.full_height=#self.menu_items*(5+self.vertical_margin*2)
        end,
        update=function(self)
            if btnp(0) then
                local idx=self.menu_items[self.selected].selected-1
                if idx==0 then idx=#self.menu_items[self.selected].option_display end
                self.menu_items[self.selected].selected=idx
            elseif btnp(1) then
                local idx=self.menu_items[self.selected].selected+1
                if idx>#self.menu_items[self.selected].option_display then idx=1 end
                self.menu_items[self.selected].selected=idx
            end
            if (btnp(2) and self.selected>1) self.selected-=1
            if (btnp(3) and self.selected<#self.menu_items) self.selected+=1
            if (btnp(4) or btnp(5)) and self.selected == self.exit_option then
                cls(13)
                sound_manager.sound_enable=self.menu_items[2].option_values[self.menu_items[2].selected]
                make_board(self.menu_items[1].option_values[self.menu_items[1].selected].size,self.menu_items[1].option_values[self.menu_items[1].selected].bombs)
                make_cursor(flr(board.size/2),flr(board.size/2))

                game.state=0
            end
        end,
    }
    options_menu:set_full_width()
    options_menu:set_full_height()
end

function make_cursor(x,y)
    cursor={
        x=x,
        y=y,
        draw=function(self)
            spr(1,self.x * 9 + board.offset_x, self.y * 9 + board.offset_y)
            -- rectfill(0,0,50,10,1)
            -- print(self.x .. "," .. self.y,2,2,5)
        end,
        action=function(self)
            -- Left
            if btnp(0) and self.x>0 then
                sound_manager:play_move_left()
                self.x-=1
            end
            -- Right
            if btnp(1) and self.x<board.size-1 then
                sound_manager:play_move_right()
                self.x+=1
            end
            -- Up
            if btnp(2) and self.y>0 then
                sound_manager:play_move_up()
                self.y-=1
            end
            -- Down
            if btnp(3) and self.y<board.size-1 then
                sound_manager:play_move_down()
                self.y+=1
            end
            local has_bomb=board:has_bomb(self.x,self.y)
            local total=board:cound_surrounding(self.x, self.y)
            if (btnp(4)) then
                self.handle_open_button(self)
            end
            if (btnp(5)) then
                self.handle_flag_button(self)
            end
        end,
        handle_flag_button=function(self)
            local tile = board:get_tile(self.x,self.y)
            if not tile:is_closed() then return end
            if tile:get_flag() then
                board:decrement_marked_bombs()
                sound_manager:play_flag_off()
                tile:set_flag(false)
            else
                board:increment_marked_bombs()
                sound_manager:play_flag_on()
                tile:set_flag(true)
            end
        end,
        handle_open_button=function(self)
            if game.start==0 then
                sound_manager:play_uncover()
                board:assign_bombs(self.x,self.y)
                board:assign_nearby()
                game.start=1
            end
            local tile = board:get_tile(self.x,self.y)
            if tile:get_flag() then return end
            tile.closed=false
            if board:has_bomb(self.x,self.y) then
                sound_manager:play_loose()
                board:uncover_all()
                game.state=2
                board:draw()
                spr(6,cursor.x * 9 + board.offset_x, cursor.y * 9 + board.offset_y)
                cursor:draw()
                hud:draw()
                wait(5)
                return
            end
            uncover_recursive(tile,board)
            sound_manager:play_uncover()
            board:count_uncovered()
            if board:is_all_uncovered() then
                sound_manager:play_win()
                board:uncover_win()
                game.state=3
                board:draw()
                cursor:draw()
                hud:draw()
                wait(30)
                return
            end
        end,
    }
end

function make_cursor_2(x,y)
    cursor_2 = {
        x=x,
        y=y,
        draw=function(self)
            local spr_number=7
            if self.x==cursor.x and self.y==cursor.y then spr_number=8 end
            spr(spr_number,self.x * 9 + board.offset_x, self.y * 9 + board.offset_y)
        end,
        action=function(self)
            -- Left
            if btnp(0,1) and self.x>0 then
                sound_manager:play_move_left()
                self.x-=1
            end
            -- Right
            if btnp(1,1) and self.x<board.size-1 then
                sound_manager:play_move_right()
                self.x+=1
            end
            -- Up
            if btnp(2,1) and self.y>0 then
                sound_manager:play_move_up()
                self.y-=1
            end
            -- Down
            if btnp(3,1) and self.y<board.size-1 then
                sound_manager:play_move_down()
                self.y+=1
            end
            local has_bomb=board:has_bomb(self.x,self.y)
            local total=board:cound_surrounding(self.x, self.y)
            if (btnp(4,1)) then
                self.handle_open_button(self)
            end
            if (btnp(5,1)) then
                self.handle_flag_button(self)
            end
        end,
        handle_flag_button=function(self)
            local tile = board:get_tile(self.x,self.y)
            if not tile:is_closed() then return end
            if tile:get_flag() then
                board:decrement_marked_bombs()
                sound_manager:play_flag_off()
                tile:set_flag(false)
            else
                board:increment_marked_bombs()
                sound_manager:play_flag_on()
                tile:set_flag(true)
            end
        end,
        handle_open_button=function(self)
            if game.start==0 then
                sound_manager:play_uncover()
                board:assign_bombs(self.x,self.y)
                board:assign_nearby()
                game.start=1
            end
            local tile = board:get_tile(self.x,self.y)
            if tile:get_flag() then return end
            tile.closed=false
            if board:has_bomb(self.x,self.y) then
                sound_manager:play_loose()
                board:uncover_all()
                game.state=2
                board:draw()
                spr(6,cursor.x * 9 + board.offset_x, cursor.y * 9 + board.offset_y)
                cursor:draw()
                hud:draw()
                wait(5)
                return
            end
            uncover_recursive(tile,board)
            sound_manager:play_uncover()
            board:count_uncovered()
            if board:is_all_uncovered() then
                sound_manager:play_win()
                board:uncover_win()
                game.state=3
                board:draw()
                cursor:draw()
                hud:draw()
                wait(30)
                return
            end
        end,
    }
end

function make_board(size,total_bombs)
    if size==nil then size=10 end
    if total_bombs==nil then total_bombs=10 end
    board={
        size=size,
        total_bombs=total_bombs,
        marked_bombs=0,
        uncovered_tiles=0,
        offset_x=0,
        offset_y=0,
        tiles={},
        add_tile=function(self,tile)
            add(self.tiles,tile)
        end,
        draw=function(self)
            for tile in all(self.tiles) do
                tile:draw()
            end
        end,
        set_bomb=function(self,index)
            self.tiles[index]:set_bomb()
        end,
        has_bomb=function(self,x,y)
            tile=self:get_tile(x,y)
            return tile:has_bomb()
        end,
        assign_bombs=function(self,exclude_x,exclude_y)
            -- create array of amount of tiles
            exclude=self:get_index(exclude_x,exclude_y)
            local a={}
            for i=1,#self.tiles do
                if i != exclude then
                    add(a,i)
                end
            end

            -- shuffle the array
            for i=1,1000 do
                rand_pos1 = flr(rnd(count(a)-1)) + 1
                rand_pos2 = flr(rnd(count(a)-1)) + 1
                aux=a[rand_pos1]
                a[rand_pos1]=a[rand_pos2]
                a[rand_pos2]=aux
            end

            -- pick the first (bomb amount elements)
            for i=1,self.total_bombs do
                self:set_bomb(a[i])
            end
        end,
        get_tile=function(self,x,y)
            local index = y*self.size+x+1
            return self.tiles[index]
        end,
        cound_surrounding=function(self,x,y)
            local total=0
            -- top left
            if x>0 and y>0 and self:get_tile(x-1,y-1):has_bomb() then
                total+=1
            end
            -- top
            if y>0 and self:get_tile(x,y-1):has_bomb() then
                 total+=1
            end
            -- top right
            if x<self.size-1 and y>0 and self:get_tile(x+1,y-1):has_bomb() then
                total+=1
            end
            -- right
            if x<self.size-1 and self:get_tile(x+1,y):has_bomb() then
                total+=1
            end
            -- bottom right
            if x<self.size-1 and y<self.size-1 and self:get_tile(x+1,y+1):has_bomb() then
                total+=1
            end
            -- bottom
            if y<self.size-1 and self:get_tile(x,y+1):has_bomb() then
                total+=1
            end
            -- bottom left
            if x>0 and y<self.size-1 and self:get_tile(x-1,y+1):has_bomb() then
                total+=1
            end
            -- left
            if x>0 and self:get_tile(x-1,y):has_bomb() then
                total+=1
            end

            return total
        end,
        get_index=function(self,x,y)
            return (y*self.size+x+1)
        end,
        assign_nearby=function(self)
            for y = 0,self.size-1 do
                for x = 0,self.size-1 do
                    local bombs_near = self:cound_surrounding(x,y)
                    self:get_tile(x,y):set_bombs_near(bombs_near)
                end
            end
        end,
        uncover_all=function(self)
            for tile in all(self.tiles) do
                if tile:has_bomb() then
                    tile:set_closed(false)
                    if tile.flag then
                        self:decrement_marked_bombs()
                    end
                end
            end
        end,
        uncover_win=function(self)
            for tile in all(self.tiles) do
                if tile:has_bomb() then
                    if tile.flag==false then
                        self:increment_marked_bombs()
                    end
                    tile:set_flag(true)
                end
            end
        end,
        increment_marked_bombs=function(self)
            self.marked_bombs+=1
        end,
        decrement_marked_bombs=function(self)
            self.marked_bombs-=1
        end,
        count_uncovered=function(self)
            local uncovered=0
            for tile in all(self.tiles) do
                if not tile:is_closed() then
                    uncovered+=1
                end
            end
            self.uncovered_tiles=uncovered
            return uncovered
        end,
        is_all_uncovered=function(self)
            return self.uncovered_tiles + self.total_bombs == self.size * self.size
        end,
    }
    board.offset_x=(128-board.size*9)/2
    board.offset_y=(118-board.size*9)/2+11
    for i = 0,board.size-1 do
        for j = 0,board.size-1 do
            board:add_tile(make_tile(j,i))
        end
    end
    cls(13)
end

function make_tile(x,y)
    local tile = {
        x=x,
        y=y,
        bomb = false,
        closed=true,
        bombs_near=0,
        flag=false,
        draw = function(self)
            if self.closed then
                spr(2,self.x * 9 + board.offset_x,self.y * 9 + board.offset_y)
                if self.flag then
                    spr(3,self.x * 9 + board.offset_x,self.y * 9 + board.offset_y)
                end
                return
            end
            if self.bomb then
                spr(5,self.x * 9 + board.offset_x,self.y * 9 + board.offset_y)
                return
            end
            spr(4,self.x * 9 + board.offset_x,self.y * 9 + board.offset_y)
            if self.bombs_near>0 then
                -- Add diferent colors to numbers
                local color = self:get_number_color(self.bombs_near)
                print(self.bombs_near,self.x * 9 + board.offset_x + 3,self.y * 9 + board.offset_y + 2,color)
            end
        end,
        get_number_color=function(self, number)
            if number==1 then return 1 end
            if number==2 then return 3 end
            if number==3 then return 8 end
            if number==4 then return 5 end
            if number==5 then return 2 end
            if number==6 then return 12 end
            if number==7 then return 1 end
            if number==8 then return 14 end
        end,
        set_bombs_near=function(self, b)
            self.bombs_near = b
        end,
        set_bomb = function(self)
            self.bomb = true
        end,
        has_bomb = function(self)
            return self.bomb
        end,
        is_closed = function(self)
            return self.closed
        end,
        set_closed=function(self,c)
            self.closed=c
        end,
        set_flag=function(self,f)
            self.flag=f
        end,
        get_flag=function(self)
            return self.flag
        end,
        get_bombs_near=function(self)
            return self.bombs_near
        end
    }
    return tile
end

function make_timer()
    timer={
        seconds=0,
        frames=0,
        update=function(self)
            self.frames+=1
            if self.frames%30==0 then
                self.seconds+=1
                if self.seconds==6000 then
                    self.seconds=0
                end
            end
            if self.frames==30 then
                self.frames=0
            end
        end,
        draw=function(self)
            local min=flr(self.seconds/60)
            local sec=self.seconds%60
            rectfill(100,2,126,8,1)
            print(pad(""..min,2) .. ":" .. pad(""..sec,2),106,2,7)
        end
    }
end

function make_hud(timer)
    hud={
        timer=timer,
        draw=function(self)
            rectfill(0,0,128,8,1)
            print(board.marked_bombs,2,2,7)
            display="mine 2020"
            if game.state==2 then display="game over" end
            if game.state==3 then display="you win!" end
            print(display,(64-#display*2),2,7)
            timer:draw()
        end,
    }
end

function make_sound_manager(enable)
    if enable==nil then enable=true end
    sound_manager={
        sound_enable=enable,
        play_move_up=function(self)
            if not self.sound_enable then return end
            sfx(1)
        end,
        play_move_right=function(self)
            if not self.sound_enable then return end
            sfx(1)
        end,
        play_move_down=function(self)
            if not self.sound_enable then return end
            sfx(0)
        end,
        play_move_left=function(self)
            if not self.sound_enable then return end
            sfx(0)
        end,
        play_flag_on=function(self)
            if not self.sound_enable then return end
            sfx(4)
        end,
        play_flag_off=function(self)
            if not self.sound_enable then return end
            sfx(5)
        end,
        play_start=function(self)
            if not self.sound_enable then return end
            sfx(6,1)
        end,
        play_win=function(self)
            if not self.sound_enable then return end
            sfx(2,1)
        end,
        play_loose=function(self)
            if not self.sound_enable then return end
            sfx(3,1)
        end,
        play_uncover=function(self)
            if not self.sound_enable then return end
            sfx(7)
        end,
    }
end

function debug(m)
    rectfill(4,110,110,128,0)
    print(m,5,117,5)
end

function any_key()
    return btnp(4)
end

function uncover_recursive(tile,board)
    tile.closed=false
    if tile.flag then
        board:decrement_marked_bombs()
    end

    if tile:get_bombs_near() > 0 then
        return
    end

    -- check top left
    if tile.x>0 and tile.y>0 then
        top_left_tile=board:get_tile(tile.x-1,tile.y-1)
        if top_left_tile:is_closed() then
            uncover_recursive(top_left_tile,board)
        end
    end

    -- check top
    if tile.y>0 then
        top_tile=board:get_tile(tile.x,tile.y-1)
        if top_tile:is_closed() then
            uncover_recursive(top_tile,board)
        end
    end

    -- check top right
    if tile.x<board.size-1 and tile.y>0 then
        top_right_tile=board:get_tile(tile.x+1,tile.y-1)
        if top_right_tile:is_closed() then
            uncover_recursive(top_right_tile,board)
        end
    end

    -- check right
    if tile.x<board.size-1 then
        right_tile=board:get_tile(tile.x+1,tile.y)
        if right_tile:is_closed() then
            uncover_recursive(right_tile,board)
        end
    end

    -- check bottom right
    if tile.x<board.size-1 and tile.y<board.size-1 then
        bottom_right_tile=board:get_tile(tile.x+1,tile.y+1)
        if bottom_right_tile:is_closed() then
            uncover_recursive(bottom_right_tile,board)
        end
    end

    -- check bottom
    if tile.y<board.size-1 then
        bottom_tile=board:get_tile(tile.x,tile.y+1)
        if bottom_tile:is_closed() then
            uncover_recursive(bottom_tile,board)
        end
    end

    -- check bottom left
    if tile.x>0 and tile.y<board.size-1 then
        bottom_left_tile=board:get_tile(tile.x-1,tile.y+1)
        if bottom_left_tile:is_closed() then
            uncover_recursive(bottom_left_tile,board)
        end
    end
end

function pad(string,length)
  if (#string==length) return string
  local leading_zeros=""
  for i=1,length-#string do
      leading_zeros = leading_zeros.."0"
  end
  return leading_zeros..string
end

function wait(a) for i = 1,a do flip() end end
__gfx__
00000000880000887777777600000000111111161111111611111116cc0000cc880000cc00000000000000000000000000000000000000000000000000000000
000000008000000876666661000000001666666716666a671a8889a7c000000c8000000c00000000000000000000000000000000000000000000000000000000
00700700000000007666666100888100166666671666866718a89a87000000000000000000000000000000000000000000000000000000000000000000000000
000770000000000076666661008a8100166666671661166718911987000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000007666666100888100166666671617116719171187000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000007666666100000100166666671611116718111987000000000000000000000000000000000000000000000000000000000000000000000000
0000000080000008766666610000010016666667166116671a9199a7c000000cc000000800000000000000000000000000000000000000000000000000000000
00000000880000886111111100000000677777776777777767777777cc0000cccc00008800000000000000000000000000000000000000000000000000000000
__label__
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddd77777777dd77777777dd11111117dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddd76666661dd76666661dd16666a67dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddd76666661dd76888161dd16668667dddddd777d777d77dd777ddddd777d777d777d777ddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddd76666661dd768a8161dd16611667dddddd777dd7dd7d7d7ddddddddd7d7d7ddd7d7d7ddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddd76666661dd76888161dd16171167dddddd7d7dd7dd7d7d77dddddd777d7d7d777d7d7ddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddd76666661dd76666161dd16111167dddddd7d7dd7dd7d7d7ddddddd7ddd7d7d7ddd7d7ddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddd76666661dd76666161dd16611667ddd7dd7d7d777d7d7d777ddddd777d777d777d777ddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddd71111111dd71111111dd77777777dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddd111d111d111dd11dd11ddddd111d11dd1d1ddddd1d1d111d1d1ddddd111dd11dddddd11d111d111d111d111ddddddddddddddddddddd
dddddddddddddddddddd1d1d1d1d1ddd1ddd1ddddddd1d1d1d1d1d1ddddd1d1d1ddd1d1dddddd1dd1d1ddddd1dddd1dd1d1d1d1dd1dddddddddddddddddddddd
dddddddddddddddddddd111d11dd11dd111d111ddddd111d1d1d111ddddd11dd11dd111dddddd1dd1d1ddddd111dd1dd111d11ddd1dddddddddddddddddddddd
dddddddddddddddddddd1ddd1d1d1ddddd1ddd1ddddd1d1d1d1ddd1ddddd1d1d1ddddd1dddddd1dd1d1ddddddd1dd1dd1d1d1d1dd1dddddddddddddddddddddd
dddddddddddddddddddd1ddd1d1d111d11dd11dddddd1d1d1d1d111ddddd1d1d111d111dddddd1dd11dddddd11ddd1dd1d1d1d1dd1dddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd77777777dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd76666661dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd76666661dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd76666661dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd76666661dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd76666661dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd76666661dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd71111111dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd77777777dd77777777dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd76666661dd76666661dddddddddd
ddddddddddd6ddd66dd6dddddd666d666d666d666ddddd6ddd6d6dd66d666dd66ddddd66dd666d666d666ddddddddddddddd76666661dd76666661dddddddddd
dddddddddd6ddd6ddddd6ddddddd6d6d6ddd6d6d6ddddd6ddd6d6d6ddd6d6d6ddddddd6d6dd6dd666d6d6ddddddddddddddd76666661dd76666661dddddddddd
dddddddddd6ddd6ddddd6ddddd666d6d6d666d6d6ddddd6ddd6d6d6ddd666d666ddddd6d6dd6dd6d6d666ddddddddddddddd76666661dd76666661dddddddddd
dddddddddd6ddd6ddddd6ddddd6ddd6d6d6ddd6d6ddddd6ddd6d6d6ddd6d6ddd6ddddd6d6dd6dd6d6d6d6ddddddddddddddd76666661dd76666661dddddddddd
ddddddddddd6ddd66dd6dddddd666d666d666d666ddddd666dd66dd66d6d6d66dddddd666d666d6d6d6d6ddddddddddddddd76666661dd76666661dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd71111111dd71111111dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd

__sfx__
00050000290501a050210500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500001f05023050270500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002975026750267502b7503075028750287502a7502a7502c75000700317500070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000c000030650326503365035650336502e6502a6502b650306502e6502b650216401e6401a6401663012620106100e6100d60009600086000060000600006000060000600006000060000600006000060000600
001000000e55019550005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
00100000185500f550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001c5501c5501c5501d55000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
010100002405023050230502305024050270503105000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
